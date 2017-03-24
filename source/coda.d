module coda;

import core.stdc.stddef: wchar_t;

extern(C++, std)
{
	//~ extern(C++, class) __gshared struct shared_ptr(T)
	//~ {
		//~ // FIXME: dirty hack, it is need to create shared_ptr by std::make_shared?2
		//~ size_t* ptr0;
		//~ size_t* ptr1;
		//~ size_t* ptr2;

		//~ T* get() // FIXME: dirty hack
		//~ {
			//~ return cast(T*) ptr0;
		//~ }
	//~ }

	extern(C++, class) struct basic_string
	(
		charT,
		traits = char_traits!charT,
		Alloc = allocator!charT
	)
	{
		void resize(size_t n);
	}

	struct char_traits(charT);

	extern(C++, class) struct allocator(T);

	alias Wstring = basic_string!wchar_t;

	class vector
	(
		T,
		Allocator = allocator!T
	);
}

extern(C++, Tools)
{
	enum Language
	{
		RU,
		EN,
		EN_FAST
	};
}

extern(C++, _sentence_splitter)
{
	class SentenceSplitter
	{
		//~ this(Tools.Language); // FIXME: unused in D

		//~ vector!size_t split(const ref Wstring);
	}
}

unittest
{
	{
		import core.stdc.locale;

		setlocale(LC_ALL,"");

		//~ auto spltr = new _sentence_splitter.SentenceSplitter(Tools.Language.RU);

		dstring input = "Сэмюэл Л. Джексон и Роберт Дауни мл. снова взялись за своё. Они стали грабить банки."; //TODO: add checking of dchar == wchar_t

		Wstring s;

		//~ spltr.split(s);

		//~ for(;;){}

		//~ vector!size_t borders; // = spltr.split(input);
		//~ assert(borders.size == 2);

		//~ input = L"Всё обошлось без серьёзных потерь и FILM:[ Принц полукровка ] продолжил лидировать, заработав 43,4 млн. долларов в 13000 кинозалах в 64 территориях за уик-энд, вместе с которыми его общая касса выросла до 493 млн. долларов международных сборов и 747,7 млн. общемировых.";
		//~ borders = spltr.split(input);
		//~ assert(borders.size == 1);
	}

	{
		//~ tokenizer = Tokenizer("RU")
		//~ disambiguator = Disambiguator("RU")
		//~ syntax_parser = SyntaxParser("RU")

		//~ #~ sentence = u'МИД пригрозил ограничить поездки американских дипломатов по России.'
		//~ #~ sentence = u'Вечером на обед были язычки колибри. В них 80 грамм углеводов, 10 граммов белка, жиров 5 грамм и 2 гр. золы. Всего 36 калорий'
		//~ #~ sentence = u'Я не хочу идти в бассейн потому что делаю распознавание текста для бота.'
		//~ #~ sentence = u'Мы с Мурзиком пошли доедать корм, жать штангу и гантели.'
		//~ #~ sentence = u'Съешь ещё этих мягких французских булок, да выпей же чаю.'
		//~ #~ sentence = u'Мама мыла раму.'
		//~ sentence = u'"закажи 3 куска сыра по килу, ну и рыбы ещё 2 кг'
		//~ tokens = tokenizer.tokenize(sentence)
		//~ disambiguated = disambiguator.disambiguate(tokens)
		//~ tree = syntax_parser.parse(disambiguated)

		//~ print tree.to_string()
		//~ tree.draw(dot_file="/tmp/tree1.dot", show=True)
	}
}
