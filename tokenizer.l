%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "structs.h"
#include "y.tab.h"

#define LOG_MODE    (false)

#define LIST				strcat(buf, yytext)
#define ADD_STRING(s)		strcat(stringBuf, s)
#define token(t) 			{LIST; if (LOG_MODE) printf("<token: %s>\n", t);}
#define tokenOperator(t)    {LIST; if (LOG_MODE) printf("<Symbol:'%c'>\n", t); return (t);}
#define tokenInteger(i) 	{LIST; if (LOG_MODE) printf("<integer:%d>\n",i); yylval.literal.type = Type_INT; yylval.literal.integer = i; return (LIT_INT);}
#define tokenReal(r)        {LIST; if (LOG_MODE) printf("<real:%e>\n",r);  yylval.literal.type = Type_REAL; yylval.literal.real = r; return (LIT_REAL);}

#define MAX_LINE_LENG 256

char buf[MAX_LINE_LENG];
char stringBuf[MAX_LINE_LENG];
int linenum = 1;

%}

%x	inBlockComment
%x	inLineComment
%x	inString

%%
<*>\r                   ;
<*>[ \t]*  			    {LIST;}

<INITIAL>\n             {
                            LIST;
                            printf("%d: %s", linenum++, buf);
                            buf[0] = '\0';
                        }

--						{
                            LIST;
                            BEGIN inLineComment;
                        }

<inLineComment>.        {
                            LIST;
                        }

<inLineComment>\n       {
                            LIST;
                            printf("%d: %s", linenum++, buf);
                            buf[0] = '\0';
                            BEGIN INITIAL;
                        }

"{"                     {
                            LIST;
                            BEGIN inBlockComment;
						}

<inBlockComment>[^\n}]  {
                            LIST;
                        }

<inBlockComment>\n        {
                            LIST;
                            printf("%d: %s", linenum++, buf);
                            buf[0] = '\0';
                        }

<inBlockComment>"}"     {
                            LIST;
                            BEGIN INITIAL;
                        }

\"                      {
                            LIST;
                            BEGIN inString;
                        }

<inString>\"\"          {
                            LIST;
                            ADD_STRING("\"");
                        }

<inString>[^\n"]+       {
                            LIST;
                            ADD_STRING(yytext);
                        }

<inString>\n            {
                            LIST;
                            printf("%d:%s\n", linenum+1, buf);
                            printf("bad character:'%s'\n",yytext);
                            exit(-1);
                        }

<inString>\"            {
                            LIST;
                            printf("<String:%s>\n",stringBuf);
                            int n = strlen(stringBuf);
                            char *tmp = malloc(n + 1);
                            strncpy(tmp, stringBuf, n);
                            tmp[n] = '\0';
                            yylval.literal.type = Type_STR;
                            yylval.literal.str = tmp;
                            stringBuf[0] = '\0';
                            BEGIN INITIAL;
                            return (LIT_STR);
                        }

[-]?[1-9][0-9]*|[0]                     {tokenInteger(atoi(yytext));}

[+-]?[0-9]+\.[0-9]+([eE][-+]?[0-9]+)?	{tokenReal(atof(yytext));}

","					{tokenOperator(',');}
":"					{tokenOperator(':');}
"."					{tokenOperator('.');}
";"					{tokenOperator(';');}
"("  				{tokenOperator('(');}
")"					{tokenOperator(')');}
"["					{tokenOperator('[');}
"]"					{tokenOperator(']');}
"+"					{tokenOperator('+');}
"-"					{tokenOperator('-');}
"*"					{tokenOperator('*');}
"/"					{tokenOperator('/');}
"%"					{tokenOperator('%');}
"<"					{tokenOperator('<');}
">"					{tokenOperator('>');}
"="					{tokenOperator('=');}


"<="				{
                       token("LE");
                       return LE;
                    }
">="				{
                       token("GE");
                       return GE;
                    }
"/="				{
                       token("NE");
                       return NE;
                    }
":="				{
                        token("ASSIGN");
                        return ASSIGN;
                    }


[bB][eE][gG][iI][nN]					{
                                            token("BEGIN");
                                            return BEGIN_;
                                        }
[bB][oO][oO][lL][eE][aA][nN]			{
                                            token("BOOLEAN");
                                            return BOOLEAN;
                                        }
[bB][rR][eE][aA][kK]					{
                                            token("BREAK");
                                            return BREAK;
                                        }
[cC][hH][aA][rR][aA][cC][tT][eE][rR]	{
                                            token("CHARACTER");
                                            return CHARACTER;
                                        }
[cC][aA][sS][eE]						{
                                            token("CASE");
                                            return CASE;
                                        }
[cC][oO][nN][tT][iI][nN][uU][eE]		{
                                            token("CONTINUE");
                                            return CONTINUE;
                                        }
[cC][oO][nN][sS][tT][aA][nN][tT]		{
                                            token("CONSTANT");
                                            return CONSTANT;
                                        }
[dD][eE][cC][lL][aA][rR][eE]			{
                                            token("DECLARE");
                                            return DECLARE;
                                        }
[dD][oO]								{
                                            token("DO");
                                            return DO;
                                        }
[eE][lL][sS][eE]						{
                                            token("ELSE");
                                            return ELSE;
                                        }
[eE][nN][dD]							{
                                            token("END");
                                            return END;
                                        }
[eE][xX][iI][tT]						{
                                            token("EXIT");
                                            return EXIT;
                                        }
[fF][lL][oO][aA][tT]					{
                                            token("FLOAT");
                                            return FLOAT;
                                        }
[fF][oO][rR]							{
                                            token("FOR");
                                            return FOR;
                                        }
[iI][fF]								{
                                            token("IF");
                                            return IF;
                                        }
[iI][nN]								{
                                            token("IN");
                                            return IN;
                                        }
[iI][nN][tT][eE][gG][eE][rR]			{
                                            token("INTEGER");
                                            return INTEGER;
                                        }
[lL][oO][oO][pP]						{
                                            token("LOOP");
                                            return LOOP;
                                        }
[pP][rR][iI][nN][tT]					{
                                            token("PRINT");
                                            return PRINT;
                                        }
[pP][rR][iI][nN][tT][lL][nN]			{
                                            token("PRINTLN");
                                            return PRINTLN;
                                        }
[pP][rR][oO][cC][eE][dD][uU][rR][eE]	{
                                            token("PROCEDURE");
                                            return PROCEDURE;
                                        }
[pP][rR][oO][gG][rR][aA][mM]			{
                                            token("PROGRAM");
                                            return PROGRAM;
                                        }
[rR][eE][tT][uU][rR][nN]				{
                                            token("RETURN");
                                            return RETURN;
                                        }
[sS][tT][rR][iI][nN][gG]				{
                                            token("STRING");
                                            return STRING;
                                        }
[tT][hH][eE][nN]						{
                                            token("THEN");
                                            return THEN;
                                        }
[wW][hH][iI][lL][eE]					{
                                            token("WHILE");
                                            return WHILE;
                                        }

[tT][rR][uU][eE]						{
                                            token("TRUE");
                                            return TRUE;
                                        }
[fF][aA][lL][sS][eE]					{
                                            token("FALSE");
                                            return FALSE;
                                        }

[aA][nN][dD]							{
                                            token("AND");
                                            return AND;
                                        }
[nN][oO][tT]							{
                                            token("NOT");
                                            return NOT;
                                        }
[oO][rR]								{
                                            token("OR");
                                            return OR;
                                        }
[Rr][Ee][Aa][Dd]                        {
                                            token("READ");
                                            return READ;
                                        }

[a-zA-Z][a-zA-Z0-9_]*   {	
                            LIST;
                            if (LOG_MODE)
                            {
                                printf("<ID:%s>\n", yytext);
                            }
                            
                            size_t n = yyleng;
                            char *nstr = malloc(n + 1);
                            strncpy(nstr, yytext, n);
                            nstr[n] = '\0'; 
                            yylval.name = nstr;
                            return ID;
                        }

<*>.                    {
                            LIST;
                            printf("%d:%s\n", linenum+1, buf);
                            printf("bad character:'%s'\n",yytext);
                            exit(-1);
                        }
