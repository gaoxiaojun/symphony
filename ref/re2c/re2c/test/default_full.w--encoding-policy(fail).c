/* Generated by re2c */
#line 1 "default_full.w--encoding-policy(fail).re"

#line 5 "<stdout>"
{
	YYCTYPE yych;

	if (YYLIMIT <= YYCURSOR) YYFILL(1);
	yych = *YYCURSOR;
	if (yych <= 0xD7FF) goto yy2;
	if (yych <= 0xDFFF) goto yy4;
yy2:
	++YYCURSOR;
#line 3 "default_full.w--encoding-policy(fail).re"
	{ return FULL; }
#line 17 "<stdout>"
yy4:
	++YYCURSOR;
#line 2 "default_full.w--encoding-policy(fail).re"
	{ return DEFAULT; }
#line 22 "<stdout>"
}
#line 4 "default_full.w--encoding-policy(fail).re"

