%{
    #include "tokens.h"
    #include "utils.h"

    struct string_buffer buff;
%}

/* To read ONLY one file at a time */
%option noyywrap
/* Recognize both uppercase (eg 'INT') and lowercase (eg 'int') keywords */
%option case-insensitive
/* Variable of type int built into Flex. Whenever Flex encounters the newline character ('\n'),
/* the variable will AUTOMATICALLY be incremented by 1 */
%option yylineno

%x SCONST
%x COMMENT

/* Class Equivalences */
WHITESPACE    [ \t\r\n\f]

IDENTIFIER    [a-zA-Z](([a-zA-Z]|[0-9])*|[_]?[a-zA-Z0-9])*_?

DECIMAL       [1-9][0-9]*
HEXADECIMAL   0[Xx][1-9a-fA-F][0-9a-fA-F]*
ICONST        {DECIMAL}|{HEXADECIMAL}|0


RCONST        ([1-9][0-9]*[.]([1-9]*|[0-9]*[1-9]+)+)|([0][.][0-9]*[Ee]?[+-]?[1-9]*[0-9]*)|(0[Xx](0|([1-9a-fA-F][0-9a-fA-F]*))\.(([0-9A-F]*[1-9A-F][0-9A-F]*))?)

/* RCONST ([1-9][0-9]*[.][1-9]*)|([0.]+|[1-9]*[0-9]*)([0-9][Ee][+-][0-9]*)|(0[Xx](0|([1-9a-fA-F][0-9a-fA-F]*))\.(([0-9A-F]*[1-9A-F][0-9A-F]*))?) */

CCONST        '.'|'\\[nftrbv]'

/* ('[ -~]')|('\\[nftrbv]') */
/* '.'|'\\[nftrbv]' */

%%

 /* key words */
"FUNCTION"               { print_token(T_FUNCTION);   return T_FUNCTION;             }
"SUBROUTINE"             { print_token(T_SUBROUTINE); return T_SUBROUTINE;           }
"END"                    { print_token(T_END);        return T_END;                  }
"COMMON"                 { print_token(T_COMMON);     return T_COMMON;               }
"INTEGER"                { print_token(T_INTEGER);    return T_INTEGER;              }
"REAL"                   { print_token(T_REAL);       return T_REAL;                 }
"LOGICAL"                { print_token(T_LOGICAL);    return T_LOGICAL;              }
"CHARACTER"              { print_token(T_CHARACTER);  return T_CHARACTER;            }
"STRING"                 { print_token(T_STRING);     return T_STRING;               }
"DATA"                   { print_token(T_DATA);       return T_DATA;                 }
"CONTINUE"               { print_token(T_CONTINUE);   return T_CONTINUE;             }
"GOTO"                   { print_token(T_GOTO);       return T_GOTO;                 }
"CALL"                   { print_token(T_CALL);       return T_CALL;                 }
"LENGTH"                 { print_token(T_LENGTH);     return T_LENGTH;               }
"READ"                   { print_token(T_READ);       return T_READ;                 }
"WRITE"                  { print_token(T_WRITE);      return T_WRITE;                }
"IF"                     { print_token(T_IF);         return T_IF;                   }
"THEN"                   { print_token(T_THEN);       return T_THEN;                 }
"ELSE"                   { print_token(T_ELSE);       return T_ELSE;                 }
"ENDIF"                  { print_token(T_ENDIF);      return T_ENDIF;                }
"DO"                     { print_token(T_DO);         return T_DO;                   }
"ENDDO"                  { print_token(T_ENDDO);      return T_ENDDO;                }
"STOP"                   { print_token(T_STOP);       return T_STOP;                 }
"RETURN"                 { print_token(T_RETURN);     return T_RETURN;               }

 /* STRINGS - Sub anylizer */
\"                       { strcpy(buff.string, "");   BEGIN(SCONST);                 }
<SCONST>\"               { BEGIN(INITIAL);
                           print_token(T_SCONST);     return T_SCONST;               }
<SCONST>(\\\n|\\\r\n)    {                                                           }
<SCONST>(\\.|[^"\\])     { string_buffer_concat_string(&buff, yytext);               }
<SCONST>(\n|\r\n)        { print_error("String: Newline found without \\.");         }
<SCONST><<EOF>>          { print_error("String: End of string without closing it."); }
<SCONST>.                { print_error("String: Unknown character.");                }

 /* comments */
"$"                      { BEGIN(COMMENT);                                           }
<COMMENT>(\n|\r\n)       { BEGIN(INITIAL);                                           }
<COMMENT>.               {                                                           }

 /* logical operators */
"\.TRUE\."|"\.FALSE\."   { print_token(T_LCONST);     return T_LCONST;               }
  
 /* operators */
"\.OR\."                 { print_token(T_OROP);       return T_OROP;                 }
"\.AND\."                { print_token(T_ANDOP);      return T_ANDOP;                }
"\.NOT\."                { print_token(T_NOTOP);      return T_NOTOP;                }
"\.GT\."|"\.GE\."|"\.LT\."|"\.LE\."|"\.EQ\."|"\.NE\." {   
                           print_token(T_RELOP);      return T_RELOP;                }
"+"|"-"                  { print_token(T_ADDOP);      return T_ADDOP;                }
"*"                      { print_token(T_MULOP);      return T_MULOP;                }
"/"                      { print_token(T_DIVOP);      return T_DIVOP;                }
"**"                     { print_token(T_POWEROP);    return T_POWEROP;              }
  
 /* other */
"("                      { print_token(T_LPAREN);     return T_LPAREN;               }
")"                      { print_token(T_RPAREN);     return T_RPAREN;               }
","                      { print_token(T_COMMA);      return T_COMMA;                }
"="                      { print_token(T_ASSIGN);     return T_ASSIGN;               }

 /* identifier */
{IDENTIFIER}             { print_token(T_ID);         return T_ID;                   }
 
 /* constants */ 
{ICONST}                 { print_token(T_ICONST);     return T_ICONST;               }
{RCONST}                 { print_token(T_RCONST);     return T_RCONST;               }
{CCONST}                 { print_token(T_CCONST);     return T_CCONST;               }

{WHITESPACE}             {                                                           }

<<EOF>>                  { print_token(T_EOF);        return T_EOF;                  }
.                        { print_error("Unrecognised character!");                   }

%%



int main(int argc, char *argv[]) {
    int token;

    if (argc < 2) {
        printf("MISSING FILE.\n");
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror("COULD NOT OPEN THE FILE.\n");
        return EXIT_FAILURE;
    }

    string_buffer_init(&buff);

    do {
        token = yylex();
    } while (token != T_EOF);

    string_buffer_destroy(&buff);

    fclose(yyin);
    yyterminate();

    return EXIT_SUCCESS;
}

void print_token(int token) {
    switch (token) {
        case T_ICONST:
        printf("[Line: %03d] INTEGER: (%-12s => %02d) \"%s\", Value: %d\n", yylineno, TOKEN_NAME[token], token, yytext, str_to_int(yytext));
        break;

        case T_RCONST:
        printf("[Line: %03d] REAL:    (%-12s => %02d) \"%s\", Value: %lf\n", yylineno, TOKEN_NAME[token], token, yytext, str_to_double(yytext));
        break;

        case T_STRING:
        printf("[Line: %03d] STRING:  \"%s\"\n", yylineno, buff.string);
        break;

        default:
        printf("[Line: %03d] TOKEN:   (%-12s => %02d) \"%s\"\n", yylineno, TOKEN_NAME[token], token, yytext);
        break;
    }
}


void print_error(const char *error_msg) {
    printf("[Line: %03d] ERROR:   %s  %s\n", yylineno, error_msg, yytext);
    /* panic method for break exit */
    yyless(1);
    exit(EXIT_FAILURE);
}
