//Eleonora Zoi Konstantoula 2116182
%{
    #include "tokens/tokens.h"
    #include "utils/utils.h"
    #include "bison/fort600.tab.h"

    #define DEBUG 0
    #define YY_USER_ACTION { FR_COL = TO_COL; FR_COL++; TO_COL += yyleng; }

    int FR_COL = 0;     /* column numbering */
    int TO_COL = 0;

    char *INPUT_FILE_NAME = NULL;

    struct string_buffer buff;
    int errors = 0;
%}


%option noyywrap

%option case-insensitive
%option yylineno

%x SCONST
%x COMMENT

/* class equivelances */
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

 /* STRINGS - sub analyzer */
\"                       { strcpy(buff.string, "");   BEGIN(SCONST);                 }
<SCONST>\"               { BEGIN(INITIAL);
                           print_token(T_SCONST);
                           yylval.symtab_ast.string = strdup(buff.string);
                           return T_SCONST;                                          }
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
                           print_token(T_RELOP);      
                           yylval.symtab_ast.string = strdup(yytext);
                                                      return T_RELOP;                }
"+"|"-"                  { print_token(T_ADDOP);      
                           yylval.symtab_ast.character = strcmp(yytext, "+") ? '-' : '+';
                           return T_ADDOP;                                           }
"*"                      { print_token(T_MULOP);      return T_MULOP;                }
"/"                      { print_token(T_DIVOP);      return T_DIVOP;                }
"**"                     { print_token(T_POWEROP);    return T_POWEROP;              }
  
 /* other */
"("                      { print_token(T_LPAREN);     return T_LPAREN;               }
")"                      { print_token(T_RPAREN);     return T_RPAREN;               }
","                      { print_token(T_COMMA);      return T_COMMA;                }
"="                      { print_token(T_ASSIGN);     return T_ASSIGN;               }

 /* identifiers */
{IDENTIFIER}             { print_token(T_ID);
                           yylval.symtab_ast.string = strdup(yytext);
                           return T_ID;                                              }
 
 /* constants */ 
{ICONST}                 { print_token(T_ICONST);
                           yylval.symtab_ast.integer = str_to_int(yytext);
                           return T_ICONST;                                          }
{RCONST}                 { print_token(T_RCONST);
                           yylval.symtab_ast.real = str_to_double(yytext);
                           return T_RCONST;                                          }
{CCONST}                 { print_token(T_CCONST);
                           yylval.symtab_ast.character = fix_escape_characters();
                           return T_CCONST;                                          }

{WHITESPACE}             {                                                           }

<<EOF>>                  { print_token(T_EOF);        return T_EOF;                  }
.                        { print_error("Unrecognised character!");                   }

%%

void print_token(int token) {
    if (DEBUG) return;

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
    ++errors;

    printf("[Line: %03d] ERROR:   %s  %s\n", yylineno, error_msg, yytext);

    if (errors == 5) {
        printf("Maximum number of errors.\n");
        exit(EXIT_FAILURE);
    }

    /* exit panic method */
    yyless(1);
    exit(EXIT_FAILURE);
}