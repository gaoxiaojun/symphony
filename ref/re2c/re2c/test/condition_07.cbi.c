/* Generated by re2c */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define	BSIZE	8192

typedef struct Scanner
{
	FILE			*fp;
	unsigned char	*cur, *tok, *lim, *eof;
	unsigned char 	buffer[BSIZE];
} Scanner;

int fill(Scanner *s, int len)
{
	if (!len)
	{
		s->cur = s->tok = s->lim = s->buffer;
		s->eof = 0;
	}
	if (!s->eof)
	{
		int got, cnt = s->tok - s->buffer;

		if (cnt > 0)
		{
			memcpy(s->buffer, s->tok, s->lim - s->tok);
			s->tok -= cnt;
			s->cur -= cnt;
			s->lim -= cnt;
		}
		cnt = BSIZE - cnt;
		if ((got = fread(s->lim, 1, cnt, s->fp)) != cnt)
		{
			s->eof = &s->lim[got];
		}
		s->lim += got;
	}
	else if (s->cur + len > s->eof)
	{
		return 0; /* not enough input data */
	}
	return -1;
}

void fputl(const char *s, size_t len, FILE *stream)
{
	while(len-- > 0)
	{
		fputc(*s++, stream);
	}
}


enum YYCONDTYPE {
	EStateR1,
	EStateR2,
};


void scan(Scanner *s)
{
	int cond = EStateR1;
	
	fill(s, 0);

	for(;;)
	{
		s->tok = s->cur;

		{
			unsigned char yych;
			if (cond < 1) {
				goto yyc_R1;
			} else {
				goto yyc_R2;
			}
/* *********************************** */
yyc_R1:
			{
				static const unsigned char yybm[] = {
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128,   0,   0,   0,   0,   0,   0, 
					  0, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128,   0,   0,   0,   0,   0, 
					  0, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
				};
				if ((s->lim - s->cur) < 2) { if(fill(s, 2) >= 0) break; }
				yych = *s->cur;
				if (yych <= '@') {
					if (yych <= '/') goto yy5;
					if (yych >= ':') goto yy5;
				} else {
					if (yych <= 'Z') goto yy3;
					if (yych <= '`') goto yy5;
					if (yych >= '{') goto yy5;
				}
yy3:
				++s->cur;
				yych = *s->cur;
				goto yy8;
yy4:
				{
					continue;
				}
yy5:
				++s->cur;
				{
					continue;
				}
yy7:
				++s->cur;
				if (s->lim <= s->cur) { if(fill(s, 1) >= 0) break; }
				yych = *s->cur;
yy8:
				if (yybm[0+yych] & 128) {
					goto yy7;
				}
				goto yy4;
			}
/* *********************************** */
yyc_R2:
			{
				static const unsigned char yybm[] = {
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128,   0,   0,   0,   0,   0,   0, 
					  0, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128,   0,   0,   0,   0,   0, 
					  0, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128, 128, 128, 128, 128, 128, 
					128, 128, 128,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
					  0,   0,   0,   0,   0,   0,   0,   0, 
				};
				if ((s->lim - s->cur) < 2) { if(fill(s, 2) >= 0) break; }
				yych = *s->cur;
				if (yych <= '@') {
					if (yych <= '/') goto yy13;
					if (yych >= ':') goto yy13;
				} else {
					if (yych <= 'Z') goto yy11;
					if (yych <= '`') goto yy13;
					if (yych >= '{') goto yy13;
				}
yy11:
				++s->cur;
				yych = *s->cur;
				goto yy16;
yy12:
				{
					continue;
				}
yy13:
				++s->cur;
				{
					continue;
				}
yy15:
				++s->cur;
				if (s->lim <= s->cur) { if(fill(s, 1) >= 0) break; }
				yych = *s->cur;
yy16:
				if (yybm[0+yych] & 128) {
					goto yy15;
				}
				goto yy12;
			}
		}

	}
}

int main(int argc, char **argv)
{
	Scanner in;
	char c;

	if (argc != 2)
	{
		fprintf(stderr, "%s <file>\n", argv[0]);
		return 1;;
	}

	memset((char*) &in, 0, sizeof(in));

	if (!strcmp(argv[1], "-"))
	{
		in.fp = stdin;
	}
	else if ((in.fp = fopen(argv[1], "r")) == NULL)
	{
		fprintf(stderr, "Cannot open file '%s'\n", argv[1]);
		return 1;
	}

	scan(&in);

	if (in.fp != stdin)
	{
		fclose(in.fp);
	}
	return 0;
}
