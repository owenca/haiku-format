class BreakConstructorInitializers {
	private: int a, b;

	public:
		BreakConstructorInitializers(int i)
			: a(i) { b = 0; }
		BreakConstructorInitializers(int i, int j);
};

BreakConstructorInitializers::BreakConstructorInitializers(int i, int j)
: a(i), b(j) {}
