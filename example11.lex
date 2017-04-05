%{

/* Declarations section */
#include <stdio.h>
#define MAX_STR_CONST 1000
void showToken(char *);
char string_buf[MAX_STR_CONST];
char *string_buf_ptr;

%}
%x str
%x ln_comment
%option yylineno
%option noyywrap
digit   		([0-9])
letter  		([a-zA-Z])
whitespace		([\t\n ])
special 		(\\\"|\\\\|\\\/|\\b|\\f|\\n|\\r|\\t)
hex_digit		([0-9a-f])
hexn 		(\\u{hex_digit}{4})

%%

\{      showToken("OBJ_START");
\}      showToken("OBJ_END");
\[      showToken("ARR_START");
\]      showToken("ARR_END");

\"      string_buf_ptr = string_buf; BEGIN(str);

<str>\"        { /* saw closing quote - all done */
        *string_buf_ptr = '\0';		
        printf("%d %s %s\n",yylineno, "STRING", string_buf);
		
		memset(string_buf, 0, sizeof(string_buf));
		BEGIN(INITIAL);
        /* return string constant token type and
         * value to parser
         */
        }
<str>[^\\\n\"]+        {
        char *yptr = yytext;

        while ( *yptr )
                *string_buf_ptr++ = *yptr++;
        }

<str>\n        {
		printf("unterminated string constant\n");
        /* error - unterminated string constant */
        /* generate error message */
        }

<str>\\u[0-9A-Fa-f]{4} {
        /* octal escape sequence */
			int result;
			char buff[40];
			memset(buff,0,sizeof(buff));
			(void) sscanf( yytext + 2, "%x", &result );

			if ( result > 0xffff ){
					printf("bad hex number\n");
					/* error, constant is out-of-bounds */
			}
			(void) sprintf(buff,"%d", result);
			*string_buf_ptr++ = '#';
			char* buff_ptr = buff;
			while(*buff_ptr){
				*string_buf_ptr++ = *buff_ptr++; 
			}
			*string_buf_ptr++ = '#';
        }
		

<str>\\u[^[0-9A-Fa-f]{4}] {
        printf("Error undefined escape sequence\n");
        /* generate error - bad escape sequence; something
         * like '\48' or '\0777777'
         */
        }

<str>\\n  *string_buf_ptr++ = '\n'; 
<str>\\\"  *string_buf_ptr++ = '\"';
<str>\\\\  *string_buf_ptr++ = '\\';
<str>\\\/  *string_buf_ptr++ = '/';
<str>\\t  *string_buf_ptr++ = '\t';
<str>\\r  *string_buf_ptr++ = '\r';
<str>\\b  *string_buf_ptr++ = '\b';
<str>\\f  *string_buf_ptr++ = '\f';
<str>\\. {printf("Error undefined escape sequence\n");
			exit(0);
		}
<str>\\(.|\n)  printf("Error undefined escape sequence\n");
				

\/\/  string_buf_ptr = string_buf; BEGIN(ln_comment);

<ln_comment>\n  { /* saw newline - all done */
        *string_buf_ptr = '\0';		
        printf("%d %s %s\n",yylineno,string_buf, "LN_COMMENT");
        memset(string_buf, 0, sizeof(string_buf));
		BEGIN(INITIAL);
        /* return string constant token type and
         * value to parser
         */
        }


.		printf("ERROR\n");
%%

void showToken(char * name)
{

        printf("%d %s %s\n",yylineno, name, yytext);
}



void ignore(){
}

