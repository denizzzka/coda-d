module coda;

import core.stdc.stddef: wchar_t;
import std.conv: to;
import std.string: toStringz;

class SentenceSplitter
{
    private cSentenceSplitter* _splitter;

    this(in Tools.Language language)
    {
        _splitter = cSentenceSplitter_create(language);
    }

    ~this()
    {
        cSentenceSplitter_destroy(_splitter);
    }

    /// @returns Sentences array
    Rstring[] split(Tstring, Rstring = string)(in Tstring line)
    {
        const wideString = line.to!( immutable(wchar_t)[] );
        auto borders = split(wideString);

        Rstring[] ret;

        size_t prev = 0;

        foreach(b; borders)
        {
            const curr = b + 1;
            ret ~= wideString[prev .. curr].to!Rstring;
            prev = curr;
        }

        return ret;
    }

    /// @returns Borders
    size_t[] split(in immutable(wchar_t)[] line)
    {
        size_t* borders;
        size_t num = cSentenceSplitter_split(_splitter, line.ptr, line.length, &borders);

        version(assert)
        {
            if(num != 0)
                assert(borders !is null);
        }

        size_t[] ret = new size_t[num];

        foreach(i, ref symbolNum; ret)
            symbolNum = borders[i];

        free_mem(borders);

        return ret;
    }
}

class Tokenizer
{
    private cTokenizer* _tokenizer;

    this(in Tools.Language language)
    {
        _tokenizer = cTokenizer_create(language);
    }

    ~this()
    {
        cTokenizer_destroy(_tokenizer);
    }

    TokensStorage tokenize(Tstring)(Tstring lineToSplit)
    {
        const s = lineToSplit.toWideStr;

        cTokensStorage* storage = cTokenizer_tokenize(_tokenizer, s.ptr, s.length);

        return new TokensStorage(storage);
    }
}

class TokensStorage
{
    private cTokensStorage* _storage;

    private this(cTokensStorage* s)
    {
        _storage = s;
    }

    ~this()
    {
        cTokensStorage_destroy(_storage);
    }
}

class DisambiguatedDataStorage
{
    private cDisambiguatedDataStorage* _storage;

    private this(cDisambiguatedDataStorage* s)
    {
        _storage = s;
    }

    ~this()
    {
        cDisambiguatedDataStorage_destroy(_storage);
    }
}

class Disambiguator
{
    private cDisambiguator* _disambiguator;

    this(in Tools.Language language)
    {
        _disambiguator = cDisambiguator_create(language);
    }

    ~this()
    {
        cDisambiguator_destroy(_disambiguator);
    }

    DisambiguatedDataStorage disambiguate(TokensStorage ts)
    {
        auto r = cDisambiguator_disambiguate(_disambiguator, ts._storage);

        return new DisambiguatedDataStorage(r);
    }
}

class SyntaxParser
{
    private cSyntaxParser* _syntaxParser;

    this(in Tools.Language language)
    {
        PrepareConsole(language);

        _syntaxParser = cSyntaxParser_create(language);
    }

    ~this()
    {
        cSyntaxParser_destroy(_syntaxParser);
    }

    SyntaxTree parse(DisambiguatedDataStorage ds)
    {
        auto r = cSyntaxParser_parse(_syntaxParser, ds._storage);

        return new SyntaxTree(r);
    }
}

class SyntaxTree
{
    private cSyntaxTree* _tree;

    private this(cSyntaxTree* t)
    {
        _tree = t;
    }

    ~this()
    {
        cSyntaxTree_destroy(_tree);
    }

    int getRootIndex() const
    {
        return cSyntaxTree_getRootIndex(_tree);
    }

    int getParentIndex(int nodeIndex) const
    {
        return cSyntaxTree_getParentIndex(_tree, nodeIndex);
    }

    SyntaxNode getNodeByIndex(int idx)
    {
        return SyntaxNode(
            cSyntaxTree_getNodeByIndex(_tree, idx)
        );
    }

    override string toString()
    {
        string ret;

        void dg(int currIdx, SyntaxNode* node, size_t depth)
        {
            string offset;

            foreach(i; 0 .. depth)
                offset ~= "  ";

            ret ~= offset ~ node.toString ~ "\n";
        }

        recursiveTraversal(&dg);

        return ret;
    }

    alias recursiveDg = void delegate(int currIdx, SyntaxNode* node, size_t depth);

    void recursiveTraversal(recursiveDg dg)
    {
        recursiveTraversal(getRootIndex, dg, 0);
    }

    void recursiveTraversal(int currIdx, recursiveDg dg, size_t depth)
    {
        auto node = getNodeByIndex(currIdx);
        dg(currIdx, &node, depth);

        auto children = node.getChildrenIndexes;

        foreach(childIdx; children)
            recursiveTraversal(childIdx, dg, depth + 1);
    }
}

struct SyntaxNode
{
    private cSyntaxNode* _node;
    private cNodeData _nd;

    this(cSyntaxNode* n)
    {
        _node = n;
        _nd = cSyntaxNode_get_cNodeData(_node);
    }

    int[] getChildrenIndexes() const
    {
        auto v = cSyntaxNode_getChildrenIndexes(_node);

        return v.cIntVector_getPtr[0 .. v.cIntVector_getLength].dup; // TODO: move to separate function
    }

    T content(T = string)() { return _nd.content.cws2wch.to!T; }
    bool isNextSpace() const { return _nd.isNextSpace; }
    T lemma(T = string)() { return _nd.lemma.cws2wch.to!T; }
    T label(T = string)() { return _nd.label.cws2wch.to!T; }
    double weight() const { return _nd.weight; }
    int lemmaId() const { return _nd.lemmaId; }

    T[] punctuation(T = string)()
    {
        auto ret = new T[_nd.punctuation_size];

        foreach(i, ref str; ret)
            str = _node.cSyntaxNode_getPunctuationByIndex(i).cws2wch.to!T;

        return ret;
    }

    string toString()
    {
        return
            "content="~content.to!string~
            " punctuation="~punctuation.to!string~
            " lemma="~lemma.to!string~
            " label="~label.to!string~
            " weight="~weight.to!string~
            " lemmaId="~lemmaId.to!string~
            " isNextSpace="~isNextSpace.to!string;
    }
}

/// Convert cWstring to wchar_t array
private wchar_t[] cws2wch(cWstring* cws)
{
    return cws.cWstring_getPtr[0 .. cws.cWstring_getLength];
}

private const (immutable(wchar_t)[]) toWideStr(Tstr)(Tstr s)
{
    return s.to!( immutable(wchar_t)[] );
}

extern(C++, Tools) @nogc
{
    public enum Language
    {
        RU,
        EN,
        EN_FAST
    };

    private void PrepareConsole(Language language);
}

private @nogc
{
    extern(C++, ccoda)
    {
        struct cSentenceSplitter;
        struct cTokenizer;
        struct cTokensStorage;
        struct cDisambiguator;
        struct cDisambiguatedDataStorage;
        struct cSyntaxParser;
        struct cSyntaxTree;
        struct cSyntaxNode;
        struct cIntVector;
        struct cWstring;

        struct cNodeData
        {
            cWstring* content;
            size_t punctuation_size;
            bool isNextSpace;
            cWstring* lemma; /**< initial form of the token*/
            cWstring* label; /**< morphology label of the token*/
            double weight; /**< weight assigned to the label by the classifier*/
            int lemmaId; /**< index of lemma in database*/
        };
    }

    extern(C++)
    {
        void free_mem(void* buf_ptr); // TODO: remove it

        size_t cIntVector_getLength(const(cIntVector)* iv);
        int* cIntVector_getPtr(const(cIntVector)* iv);

        size_t cWstring_getLength(const cWstring* v);
        wchar_t* cWstring_getPtr(cWstring* v);

        cSentenceSplitter* cSentenceSplitter_create(Tools.Language);
        void cSentenceSplitter_destroy(cSentenceSplitter*);
        size_t cSentenceSplitter_split(cSentenceSplitter* splitter, const(wchar_t)* line_to_split, size_t line_length, size_t** borders);

        cTokenizer* cTokenizer_create(Tools.Language language);
        void cTokenizer_destroy(cTokenizer* tokenizer);
        cTokensStorage* cTokenizer_tokenize(cTokenizer* tokenizer, const(wchar_t)* line_to_split, size_t line_length);

        void cTokensStorage_destroy(cTokensStorage* ts);

        cDisambiguator* cDisambiguator_create(Tools.Language language);
        void cDisambiguator_destroy(cDisambiguator* d);
        cDisambiguatedDataStorage* cDisambiguator_disambiguate(cDisambiguator* d, cTokensStorage* parsedTokens);

        void cDisambiguatedDataStorage_destroy(cDisambiguatedDataStorage* ds);

        cSyntaxParser* cSyntaxParser_create(Tools.Language language);
        void cSyntaxParser_destroy(cSyntaxParser* sp);
        cSyntaxTree* cSyntaxParser_parse(cSyntaxParser* syntax_parser, cDisambiguatedDataStorage* dds);

        void cSyntaxTree_destroy(cSyntaxTree* t);

        cSyntaxNode* cSyntaxTree_getNodeByIndex(cSyntaxTree* tree, size_t idx);
        int cSyntaxTree_getRootIndex(const(cSyntaxTree)* tree);
        int cSyntaxTree_getParentIndex(const(cSyntaxTree)* tree, int nodeIndex);

        cIntVector* cSyntaxNode_getChildrenIndexes(const(cSyntaxNode)* node);
        cNodeData cSyntaxNode_get_cNodeData(cSyntaxNode* node);
        cWstring* cSyntaxNode_getPunctuationByIndex(cSyntaxNode* node, size_t idx);
    }
}

unittest
{
    {
        import core.stdc.locale;

        setlocale(LC_ALL, "");

        auto splitter = new SentenceSplitter(Tools.Language.RU);

        string input = "Мальчик квадратный ковер выбивает. Дедушка круглый арбуз доедает... Тов. лейтенант, принесите 2 кг. арбузов!";

        auto res = splitter.split(input);

        assert(res.length == 3);
        assert(res[0] == "Мальчик квадратный ковер выбивает.");
        assert(res[1] == " Дедушка круглый арбуз доедает...");
        assert(res[2] == " Тов. лейтенант, принесите 2 кг. арбузов!");

        auto tokenizer = new Tokenizer(Tools.Language.RU);
        auto tokens = tokenizer.tokenize("Ежихи, постойте!");

        auto disambiguator = new Disambiguator(Tools.Language.RU);
        auto disambiguated = disambiguator.disambiguate(tokens);

        auto syntax_parser = new SyntaxParser(Tools.Language.RU);
        auto tree = syntax_parser.parse(disambiguated);
        auto root = tree.getRootIndex;
        assert(root == 1);

        auto rootNode = tree.getNodeByIndex(root);
        assert(rootNode.lemma == "постоять");

        auto childrenIdxs = rootNode.getChildrenIndexes;
        assert(childrenIdxs == [0]);

        auto childNode = tree.getNodeByIndex(childrenIdxs[0]);
        assert(childNode.lemma == "ежиха");
        assert(childNode.label == "S@МН@ЖЕН@ИМ@ОД");
        assert(childNode.punctuation == [","]);

        auto parentIdx = tree.getParentIndex(childrenIdxs[0]);
        assert(root == parentIdx);
    }
}
