%{
    #include "utils.h"
    #include "extra/hashtbl.h"
    #include <stdio.h>
    
    extern struct string_buffer buff;
    extern FILE* yyin;
    extern int yylex();
    extern int yylineno;

    HASHTBL *hashtable;
    int scope = 0;
    int syntax_errors = 0;

    // Πρέπει να κάνουμε define την yyerror για να τρέξει.
    extern void yyerror(const char* err) {
        ++syntax_errors;
        fprintf(stderr, "[Line: %03d] Error: %s\n", yylineno, err);
        
        if (syntax_errors == 5) {
            printf("Maximum number of syntax errors.\n");
            exit(EXIT_FAILURE);
        }

        // yyerrok;
    }
%}

%define parse.error verbose

%union {
  int integer;
  double real;
  _Bool logical;
  char character;
  const char *string;
}

// ΛΕΞΕΙΣ ΚΛΕΙΔΙΑ
%token T_FUNCTION 1 "function"
%token T_SUBROUTINE 2 "subroutine"
%token T_END 3 "end"
%token T_COMMON 4 "common"
%token T_INTEGER 5 "integer"
%token T_REAL 6 "real"
%token T_LOGICAL 7 "logical"
%token T_CHARACTER 8 "character"
%token T_STRING 9 "string"
%token T_DATA 10 "data"
%token T_CONTINUE 11 "continue"
%token T_GOTO 12 "goto"
%token T_CALL 13 "call"
%token T_LENGTH 14 "length"
%token T_READ 15 "read"
%token T_WRITE 16 "write"
%token T_IF 17 "if"
%token T_THEN 18 "then"
%token T_ELSE 19 "else"
%token T_ENDIF 20 "endif"
%token T_DO 21 "do"
%token T_ENDDO 22 "enddo"
%token T_STOP 23 "stop"
%token T_RETURN 24 "return"

// ΑΝΑΓΝΩΡΙΣΤΙΚΟ
%token <string> T_ID 25 "id"

// ΣΤΑΘΕΡΕΣ
%token <integer> T_ICONST 26 "iconst"
%token <real> T_RCONST 27 "rconst"
%token <logical> T_LCONST 28 "lconst"
%token <character> T_CCONST 29 "cconst"
%token <string> T_SCONST 30 "sconst"

// ΤΕΛΕΣΤΕΣ
%token T_OROP 31 ".or."
%token T_ANDOP 32 ".and."
%token T_NOTOP 33 ".not."
%token T_RELOP 34 ".gt. .ge. .lt. .le. .eq. .ne."
%token T_ADDOP 35 "+ -"
%token T_MULOP 36 "*"
%token T_DIVOP 37 "/"
%token T_POWEROP 38 "**"

// ΑΛΛΕΣ ΛΕΚΤΙΚΕΣ ΜΟΝΑΔΕΣ
%token T_LPAREN 39 "("
%token T_RPAREN 40 ")"
%token T_COMMA 41 ","
%token T_ASSIGN 42 "="

// EOF
%token T_EOF 0 "<EOF>"

/* %type <string> program body declarations couplespec type vars undef_variable dims dim vals
%type <string> value_list values value repeat simp_constant constant coup_constant statements
%type <string> labeled_statement label statement simple_statement assignment variable expressions
%type <string> expression goto_statement labels if_statement subroutine_call io_statement read_list
%type <string> read_item iter_space step write_list write_item compound_statement branch_statement
%type <string> tail loop_statement subprograms subprogram header formal_parameters */

%left T_MULOP
%left T_DIVOP
%left T_ADDOP
%left T_ANDOP
%left T_OROP

%right T_POWEROP

%nonassoc T_NOTOP
%nonassoc T_RELOP

%start program /* Optional */

%%
    /* Syntax Rules */
program: body T_END { hashtbl_get(hashtable, scope); } subprograms
       ;

body: declarations statements
    ;

declarations: declarations type vars
            | declarations T_COMMON cblock_list
            | declarations T_DATA vals
            | %empty { }
            ;

type: T_INTEGER
    | T_REAL
    | T_LOGICAL
    | T_CHARACTER
    | T_STRING
    ;

vars: vars T_COMMA undef_variable
    | undef_variable
    ;

undef_variable: T_ID T_LPAREN dims T_RPAREN         { hashtbl_insert(hashtable, $1, NULL, scope); }
              | T_ID                                { hashtbl_insert(hashtable, $1, NULL, scope); }
              ;

dims: dims T_COMMA dim
    | dim
    ;

dim: T_ICONST
   | T_ID                                { hashtbl_insert(hashtable, $1, NULL, scope); }
   ;

cblock_list: cblock_list cblock
           | cblock
           ;

cblock: T_DIVOP T_ID T_DIVOP id_list    { hashtbl_insert(hashtable, $2, NULL, scope); }
      ;

id_list: id_list T_COMMA T_ID           { hashtbl_insert(hashtable, $3, NULL, scope); }
       | T_ID                           { hashtbl_insert(hashtable, $1, NULL, scope); }
       ;

vals: vals T_COMMA T_ID value_list      { hashtbl_insert(hashtable, $3, NULL, scope); }
    | T_ID value_list                   { hashtbl_insert(hashtable, $1, NULL, scope); }
    ;

value_list: T_DIVOP values T_DIVOP
          ;

values: values T_COMMA value
      | value
      ;

value: T_ADDOP constant
     | T_MULOP T_ADDOP constant
     | constant
     | T_MULOP constant
     ;

constant: T_ICONST
        | T_RCONST
        | T_LCONST
        | T_CCONST
        | T_SCONST
        ;

statements: statements labeled_statement
          | labeled_statement
          ;

labeled_statement: label statement
                 | statement
                 ;

label: T_ICONST
     ;

statement: simple_statement
         | compound_statement
         ;

simple_statement: assignment
                | goto_statement
                | if_statement
                | subroutine_call
                | io_statement
                | T_CONTINUE
                | T_RETURN
                | T_STOP
                ;

assignment: variable T_ASSIGN expression
          ;

variable: T_ID T_LPAREN expressions T_RPAREN        { hashtbl_insert(hashtable, $1, NULL, scope); }
        | T_ID                                      { hashtbl_insert(hashtable, $1, NULL, scope); }
        ;

expressions: expressions T_COMMA expression
            | expression
            ;

expression: expression T_OROP expression
          | expression T_ANDOP expression
          | expression T_RELOP expression
          | expression T_ADDOP expression
          | expression T_MULOP expression
          | expression T_DIVOP expression
          | expression T_POWEROP expression
          | T_NOTOP expression
          | T_ADDOP expression
          | variable
          | constant
          | T_LPAREN expression T_RPAREN
          | T_LENGTH T_LPAREN expression T_RPAREN
          ;

goto_statement: T_GOTO label
              | T_GOTO T_ID T_COMMA T_LPAREN labels T_RPAREN            { hashtbl_insert(hashtable, $2, NULL, scope); }
              ;

labels: labels T_COMMA label
      | label
      ;

if_statement: T_IF T_LPAREN expression T_RPAREN label T_COMMA label T_COMMA label
            | T_IF T_LPAREN expression T_RPAREN simple_statement
            | T_IF error expression T_RPAREN simple_statement           { yyerror("Missing '('"); yyerrok; }
            | T_IF T_LPAREN expression error simple_statement           { yyerror("Missing ')'"); yyerrok; }
            ;

subroutine_call: T_CALL variable
               ;

io_statement: T_READ read_list
            | T_WRITE write_list
            ;

read_list: read_list T_COMMA read_item
         | read_item
         ;

read_item: variable
         | T_LPAREN read_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN         { hashtbl_insert(hashtable, $4, NULL, scope); }
         ;

iter_space: expression T_COMMA expression step
          ;

step: T_COMMA expression
    | %empty { }
    ;

write_list: write_list T_COMMA write_item
          | write_item
          ;

write_item: expression
          | T_LPAREN write_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN       { hashtbl_insert(hashtable, $4, NULL, scope); }
          ;

compound_statement: branch_statement
                  | loop_statement
                  ;

branch_statement: T_IF T_LPAREN expression T_RPAREN T_THEN { scope++; } body tail            { hashtbl_get(hashtable, scope); scope--; }
                ;

tail: T_ELSE body T_ENDIF
    | T_ENDIF
    ;

loop_statement: T_DO T_ID { hashtbl_insert(hashtable, $2, NULL, scope); } T_ASSIGN iter_space { scope++; } body T_ENDDO          { hashtbl_get(hashtable, scope); scope--; }
              ;

subprograms: subprograms subprogram
           | %empty { }
           ;

subprogram: header body T_END                 { hashtbl_get(hashtable, scope); scope--; }
          ;

header: type T_FUNCTION T_ID { hashtbl_insert(hashtable, $3, NULL, scope); } T_LPAREN { scope--; } formal_parameters T_RPAREN
      | T_SUBROUTINE T_ID { hashtbl_insert(hashtable, $2, NULL, scope); } T_LPAREN { scope--; } formal_parameters T_RPAREN
      | T_SUBROUTINE T_ID { hashtbl_insert(hashtable, $2, NULL, scope); }
      ;

formal_parameters: type vars T_COMMA formal_parameters
                 | type vars
                 ;

%%

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("MISSING FILE.\n");
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror("COULD NOT OPEN THE FILE.\n");
        return EXIT_FAILURE;
    }

    if (!(hashtable = hashtbl_create(10, NULL))) {
        perror("[ERROR] Failed to initialize hashtable.");
        exit(EXIT_FAILURE);
    }

    string_buffer_init(&buff);

    yyparse();

    fclose(yyin);
    hashtbl_destroy(hashtable);
    string_buffer_destroy(&buff);

    return EXIT_SUCCESS;
}