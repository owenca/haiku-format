int BreakBeforeBraces(int n) {
	switch(n) {
	case 1: return 0;
	case 2: ++n; break;
	case 3: /* a comment */ {
		int i;
		for (i = 0; i < 5; ++i)
		{
			n += i;
		}
		break;
	}
	default: { int i; for (i = 5; i > 0; --i) n-= i; }
	}
	
	return n;
}
