/* Generated by re2c */
#line 1 "range_dot.x.re"

#line 5 "<stdout>"
{
	YYCTYPE yych;

	if ((YYLIMIT - YYCURSOR) < 2) YYFILL(2);
	yych = *YYCURSOR;
	if (yych == '\n') goto yy2;
	if (yych <= 0xD7FF) goto yy3;
	if (yych <= 0xDBFF) goto yy5;
	goto yy3;
yy2:
yy3:
	++YYCURSOR;
yy4:
#line 2 "range_dot.x.re"
	{return 0;}
#line 21 "<stdout>"
yy5:
	++YYCURSOR;
	if ((yych = *YYCURSOR) <= 0xDBFF) goto yy4;
	if (yych <= 0xDFFF) goto yy3;
	goto yy4;
}
#line 3 "range_dot.x.re"

