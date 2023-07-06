%{
    #include "utils/utils.h"

    int scope = 0;
    int syntax_errors = 0;

    hash_table_t *my_hashtable; /* ΠΣ Αρχικοποίηση */

    /* --- Σημασιολογική Διαδιακασία - βοηθητικές μεταβλητές --- */

    /* βοηθητικά pointers */
    char *pch;
    list_t *curr;
   

    init_values *head_init; /* αρχή λίστας */
    init_values *init;      /* init: λίστα που κρατάει τις αρχικοποιήσεις του αναγνωριστικού
                            * εαν μια μόνο μεταβλητή είναι αρχικοποιημένη, το init κρατάει μόνο
                            * έναν κόμβο, το init δημιουργείται στο πλαίσιο της σημασιολογικής διαδικασίας
                            * η λίστα αρχικοποιήται κάθε φορά*/

    /* --- Σημασιολογική Διαδιακασία - βοηθητικές μεταβλητές --- */

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
    extern int yylex();
%}

%define parse.error verbose

%union {
    struct {
        int integer;
        double real;
        _Bool logical;
        char character;
        char *string;

        /* τύπος και κατηγορία */
        Type t;
        Complex_Type c_t;

        struct {
                Type type;
                Complex_Type c_type;
                /* other fields */
        } v;	/* for expressions */


        /* info_struct
            * Χρησιμοποιήτε για να περαστούν περισσοτέρες πληροφορίες στην σημασιολογική ανάλυση
            * τον μη τερματικών συμβόλων.
            * <<Δεν χρησιμοποιούνται όλα για τα μη τερματικά>>
            * value_list : type,cat,params
            * value : type,cat
        */
        struct {
            Type type;		/* τύπος */
            Complex_Type c_type;	/* κατηγορία  */
            char *str;		/* αποθήκευση πολλαπλών IDs */
            int params;		/* ελάχιστος αριθμός παραμέτρων */
            initialization_t basic_types;
        } info_str;

        struct {
            AST_expr_T *expr_node;
            AST_cmd_T  *cmd_node;
        } ast;

        /*A. Συνάρτηση παραμέτρων λίστα */
        struct params_t *params;
    } symtab_ast;
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
%token <symtab_ast.string> T_STOP 23 "stop"
%token <symtab_ast.string> T_RETURN 24 "return"

// ΑΝΑΓΝΩΡΙΣΤΙΚΟ
%token <symtab_ast.string> T_ID 25 "id"

// ΣΤΑΘΕΡΕΣ
%token <symtab_ast.integer> T_ICONST 26 "iconst"
%token <symtab_ast.real> T_RCONST 27 "rconst"
%token <symtab_ast.logical> T_LCONST 28 "lconst"
%token <symtab_ast.character> T_CCONST 29 "cconst"
%token <symtab_ast.string> T_SCONST 30 "sconst"

// ΤΕΛΕΣΤΕΣ
%token T_OROP 31 ".or."
%token T_ANDOP 32 ".and."
%token T_NOTOP 33 ".not."
%token <symtab_ast.string> T_RELOP 34 ".gt. .ge. .lt. .le. .eq. .ne."
%token <symtab_ast.character> T_ADDOP 35 "+ -"
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

/* 
   program declarations couplespec
   repeat simp_constant coup_constant statements
   labeled_statement statement
   subprograms subprogram header
*/

%type <symtab_ast.t> type

%type <symtab_ast.params> formal_parameters

%type <symtab_ast.string> vars
%type <symtab_ast.string> undef_variable

%type <symtab_ast> constant
%type <symtab_ast> labels
%type <symtab_ast> label
%type <symtab_ast> value_list
%type <symtab_ast> values
%type <symtab_ast> value
%type <symtab_ast> io_statement
%type <symtab_ast> simple_statement
%type <symtab_ast> subroutine_call
%type <symtab_ast> variable
%type <symtab_ast> assignment
%type <symtab_ast> expressions
%type <symtab_ast> expression
%type <symtab_ast> goto_statement
%type <symtab_ast> read_list
%type <symtab_ast> write_list
%type <symtab_ast> read_item
%type <symtab_ast> write_item
%type <symtab_ast> iter_space
%type <symtab_ast> if_statement
%type <symtab_ast> if_labels
%type <symtab_ast> compound_statement
%type <symtab_ast> branch_statement
%type <symtab_ast> tail
%type <symtab_ast> loop_statement
%type <symtab_ast> body

%type <symtab_ast.string> dims
%type <symtab_ast.string> dim
%type <symtab_ast.string> id_list


%left T_MULOP
%left T_DIVOP
%left T_ADDOP
%left T_ANDOP
%left T_OROP

%right T_POWEROP

%nonassoc T_NOTOP
%nonassoc T_RELOP

%start program

%%
    /* Syntax Rules */
program             : body T_END { mkcmd_end(); } subprograms
                    ;

body                : { scope++; /* put */ } declarations statements { print_hashtable(my_hashtable); scope--; delete_scope(my_hashtable, scope);  }
                    ;

declarations        : declarations type vars
                    {
                        printf("vars = count\n");
                        pch = strtok ($3, "%");
                        while (pch != NULL) {
                            curr = lookup_identifier(my_hashtable, pch, scope);
                            curr->type = $2;
                            pch = strtok (NULL, "%");
                        }
                        free($3);
                    }
                    | declarations T_COMMON cblock_list
                    | declarations T_DATA vals
                    | %empty { }
                    ;

type                : T_INTEGER                                   { $$ = TY_integer;   }
                    | T_REAL                                      { $$ = TY_real;      }
                    | T_LOGICAL                                   { $$ = TY_logical;   }
                    | T_CHARACTER                                 { $$ = TY_character; }
                    | T_STRING                                    { $$ = TY_string;    }
                    ;

vars                : vars T_COMMA undef_variable
                    {
                        if ($1 == NULL && $3 != NULL)
                            $$ = $3;
                        else if ($3 != NULL && $1 != NULL)
                            $$ = str_append($1, $3);
                        else
                            $$ = $1;
                    }
                    | undef_variable
                    {
                        if ($1 != NULL)
                            $$ = $1;
                        else
                            $$ = NULL;
                    }
                    ;

undef_variable      : T_ID T_LPAREN dims T_RPAREN
                    {
                        if (install(my_hashtable, scope, TY_unknown, C_array, $1) == NULL) {
                            $$ = $1;
                            /* pass the dimensions of id in hash table */
                            curr = context_check(my_hashtable, scope, $1);
                            if ($3 != NULL)
                                curr->id_info.init_n.dimensions = strdup($3);
                        } else
                            $$ = NULL;
                    }
                    | T_ID
                    {
                        if (install(my_hashtable, scope, TY_unknown, C_variable, $1) == NULL)
                            $$ = $1;
                        else
                            $$ = NULL;
                    }
                    ;

dims                : dims T_COMMA dim
                    {   /*same as vars rule*/
                        if ($1 == NULL && $3 != NULL)
                            $$ = $3;
                        else if ($3 != NULL && $1 != NULL)
                            $$ = str_append($1, $3);
                        else
                            $$ = $1;
                    }
                    | dim
                    {
                        if ($1 != NULL)
                            $$ = $1;
                        else
                            $$ = NULL;
                    }
                    ;

dim                 : T_ICONST
                    {
                        /* allocate enough bytes to satisfy even the largest
                        * integer in fort600 */
                        $$ = (char *)malloc(20);
                        sprintf($$, "%d", $1);
                    }
                    | T_ID
                    {
                        if (context_check(my_hashtable, scope, $1) != NULL)
                            $$ = $1;
                        else
                            $$ = NULL;
                    }
                    ;

cblock_list         : cblock_list cblock
                    | cblock
                    ;

cblock              : T_DIVOP T_ID T_DIVOP id_list
                    {
                        install(my_hashtable, scope, TY_unknown, C_common, $2);
                    }
                    ;

id_list             : id_list T_COMMA T_ID
                    {
                        /* check Symbol Table */
                        if (context_check(my_hashtable, scope, $3) != NULL)
                            /* keep the id for the next rules */
                            $$ = str_append($1, $3);
                    }
                    | T_ID
                    {
                        /* check Symbol Table */
                        if (context_check(my_hashtable, scope, $1) != NULL)
                            $$ = $1;
                    }
                    ;

vals                : vals T_COMMA T_ID value_list
                    {	/* Initialization block*/
                        curr = context_check(my_hashtable, scope, $3);
                        if (curr != NULL) {
                            /* validate the consistency of the initializations */
                            if (curr->type != $4.info_str.type) {
                                ERROR(stderr, "Sematic Error2. Incorrect type");
                                /* SEM_ERROR = 1; */
                            }
                            /* list - array check*/
                            if (curr->cat != $4.info_str.c_type) {
                                if (curr->cat == C_list &&
                                    $4.info_str.c_type == C_array) {
                                /* check whether values == 0 */

                                    /* !_insert_list_! */
                                    curr->id_info.init_n.init = head_init; /*&($4.init);*/
                                } else if (curr->cat == C_array &&
                                    $4.info_str.c_type == C_variable) {
                                    /*Initialize all other elements with 0 */

                                    /* !_insert_list_! */
                                    curr->id_info.init_n.init = head_init;/*&($4.init);*/

                                } else {
                                    ERROR(stderr, "Sematic Error2. Incorrect category");
                                    /* SEM_ERROR = 1; */
                                }
                            } else {
                                /* !_insert_list_! */
                                curr->id_info.init_n.init = head_init;/*&($4.init);*/
                            }
                            /* pre initializations */
                            /* 2.2 if id is variable we want to assign its initialization value to symbol table */
                            /* if id is array or list we follow different procedures (me tous xwrous dedomenwn?)*/
                            /*if(initialize_id(curr,$4.str)){
                                ERROR(stderr, "Memory Allocation Error.");
                                // SEM_ERROR = 1;
                            }*/
                        }
                    }
                    | T_ID value_list
                    {
                        curr = context_check(my_hashtable, scope, $1);
                        if (curr != NULL) {
                            /*validate the consistency of the initializations*/
                            if(curr->type != $2.info_str.type) {
                                /*printf("type %s and cat %s\n",typeNames[$2.type],catNames[$2.cat]);*/
                                ERROR(stderr, "Sematic Error1. Initialization");
                                /* SEM_ERROR = 1; */
                            }
                            if (curr->cat != $2.info_str.c_type) {
                                if (curr->cat == C_list &&
                                    $2.info_str.c_type == C_array) {
                                /* check whether values == 0*/

                                    /* !_insert_list_! */
                                        curr->id_info.init_n.init = head_init;/*&($2.init);*/

                                } else if (curr->cat == C_array &&
                                        $2.info_str.c_type == C_variable) {
                                /*Initialize all other elements with 0*/

                                    /* !_insert_list_! */
                                    curr->id_info.init_n.init = head_init;/*&($2.init);*/
                                } else {
                                    ERROR(stderr, "Sematic Error1. Incorrect "
                                        "category ID %s, type %s", catNames[curr->cat],
                                                    catNames[$2.info_str.c_type]);
                                    /* SEM_ERROR = 1; */
                                }
                            } else {	/* !_insert_list_! */
                                curr->id_info.init_n.init = head_init;/*&($2.init);*/
                            }
                            /* pre initializations */
                            /* 2.2 if id is variable we want to assign its initialization value to symbol table */
                            /* if id is array or list we follow different procedures (me tous xwrous dedomenwn?)*/
                            /*if(initialize_id(curr,$2.str)){
                                ERROR(stderr, "Memory Allocation Error.");
                                // SEM_ERROR = 1;
                            }*/
                        }
                    }
                    ;

value_list          : T_DIVOP values T_DIVOP     { $$.info_str = $2.info_str; }
                    ;

values              : values T_COMMA value
                    {
                        init_values *curr;

                        if ($1.info_str.type == $3.info_str.type) {
                            $$.info_str.type = $1.info_str.type;
                            /* I have many values therefore array (or list?)*/
                            $$.info_str.c_type = C_array;
                            $$.info_str.params = $1.info_str.params + $3.info_str.params;
                        
                            /* time to form a list ! */
                            /* first initializatins go to the back of the list */
                            for (curr = head_init; curr != NULL; curr = curr->next) {
                                if (curr->next == NULL) {
                                    curr->next = init;
                                    break;
                                }
                            }
                        }
                    }
                    | value
                    {
                        $$.info_str.type = $1.info_str.type;
                        $$.info_str.c_type = $1.info_str.c_type;
                        $$.info_str.params = 1;

                        /* initializations node :: first on the list */
                        head_init = init;
                    }
                    ;

value               : T_ADDOP constant
                    {
                        if ($2.info_str.type == TY_character || $2.info_str.type == TY_logical ||
                            $2.info_str.type == TY_string) {
                            ERROR(stderr, "Semantic fault. Incorrect type");
                            /* SEM_ERROR = 1; */
                        } else {
                            $$.info_str.type = $2.info_str.type;
                            $$.info_str.c_type = C_variable;

                            init = create_init_node();
                            init = initialize_node(init, $2.info_str.type, $2.info_str.basic_types, 1);

                            if ($1 == '+') { /* nothing  */ }
                            else {	/* ADDOP is '-' */
                                if ($2.info_str.type == TY_integer) {
                                    init->initialization.intval =
                                        -init->initialization.intval;
                                } else if ($2.info_str.type == TY_real) {
                                    init->initialization.realval =
                                        -init->initialization.realval;
                                }
                            }
                        }
                    }
                    | T_MULOP T_ADDOP constant
                    {
                        if ($3.info_str.type == TY_character || $3.info_str.type == TY_logical ||
                            $3.info_str.type == TY_string) {
                            ERROR(stderr, "Semantic fault. Incorrect type");
                            /* SEM_ERROR = 1; */
                        } else {
                            $$.info_str.type = $3.info_str.type;
                            $$.info_str.c_type = C_variable;

                            init = create_init_node();
                            init = initialize_node(init, $3.info_str.type, $3.info_str.basic_types, 1);

                            if ($2 == '+') { /* nothing  */ }
                            else {	/* ADDOP is '-' */
                                if ($3.info_str.type == TY_integer) {
                                    init->initialization.intval =
                                        -init->initialization.intval;
                                } else if ($3.info_str.type == TY_real) {
                                    init->initialization.realval =
                                        -init->initialization.realval;
                                }
                            }
                        }
                    }
                    | constant
                    {
                        $$.info_str.type = $1.info_str.type;
                        $$.info_str.c_type = C_variable;

                        /* init node initialization */
                        init = create_init_node();
                        init = initialize_node(init, $1.info_str.type, $1.info_str.basic_types, 1);
                    }
                    | T_MULOP constant
                    {
                        $$.info_str.type = $2.info_str.type;
                        $$.info_str.c_type = C_variable;

                        init = create_init_node();
                        init = initialize_node(init, $2.info_str.type, $2.info_str.basic_types, 1);

                        if ($2.info_str.type == TY_integer) {
                            init->initialization.intval =
                                init->initialization.intval;
                        } else if ($2.info_str.type == TY_real) {
                            init->initialization.realval =
                                init->initialization.realval;
                        } else if ($2.info_str.type == TY_character) {
                            init->initialization.charval =
                                init->initialization.charval;
                        }
                    }
                    ;

constant            : T_ICONST
                    {
                        $$.info_str.type = TY_integer;
                        $$.info_str.basic_types.intval = $1;
                        $$.ast.expr_node = mkleaf_int($1);
                    }
                    | T_RCONST
                    {
                        $$.info_str.type = TY_real;
                        $$.info_str.basic_types.realval = $1;
                        $$.ast.expr_node = mkleaf_real($1);
                    }
                    | T_LCONST
                    {
                        $$.info_str.type = TY_logical;
                        $$.info_str.basic_types.charval = $1;
                        $$.ast.expr_node = mkleaf_bool($1);
                    }
                    | T_CCONST
                    {
                        $$.info_str.type = TY_character;
                        $$.info_str.basic_types.charval = $1;
                        $$.ast.expr_node = mkleaf_char($1);
                    }
                    | T_SCONST
                    {
                        $$.info_str.type = TY_string;
                        $$.info_str.basic_types.string = $1;
                        $$.ast.expr_node= mkleaf_string($1);
                    }
                    ;

statements          : statements labeled_statement
                    | labeled_statement
                    ;

labeled_statement   : label statement
                    | statement
                    ;

label               : T_ICONST  { $$.ast.expr_node = mkleaf_int($1); }
                    ;

statement           : simple_statement
                    | compound_statement
                    ;

simple_statement    : assignment           { $$.ast.cmd_node = mkcmd_assign($1.ast.expr_node);              }
                    | goto_statement       { $$.ast.cmd_node = mkcmd_goto($1.ast.expr_node);                }
                    | if_statement         { $$.ast.cmd_node = $1.ast.cmd_node;                             }
                    | subroutine_call      { $$.ast.cmd_node = mkcmd_call($1.ast.expr_node);                }
                    | io_statement         { $$.ast.cmd_node = mkcmd_io($1.ast.expr_node, $1.ast.cmd_node); }
                    | T_CONTINUE
                    | T_RETURN
                    | T_STOP
                    ;

assignment          : variable T_ASSIGN expression
                    { $$.ast.expr_node = mknode_assign($1.ast.expr_node, $3.ast.expr_node); }
                    ;

variable            : T_ID T_LPAREN expressions T_RPAREN
                    {
                        list_t *id = context_check(my_hashtable, scope, $1);
                        if (id != NULL)
                            $$.ast.expr_node = mknode_paren(mkleaf_id(id), $3.ast.expr_node);
                    }
                    | T_ID
                    {
                        list_t *id = context_check(my_hashtable, scope, $1);
                        if (id) {
                            $$.t = id->type;
                            $$.ast.expr_node = mkleaf_id(id);
                        } else
                            $$.t = TY_invalid;
                    }
                    ;

expressions         : expressions T_COMMA expression          { $$.ast.expr_node = mknode_comma($1.ast.expr_node, $3.ast.expr_node); }
                    | expression                              { $$.ast.expr_node = $1.ast.expr_node;                                 }
                    ;

expression          : expression T_OROP expression            { $$.ast.expr_node = mknode_or($1.ast.expr_node, $3.ast.expr_node);    }
                    | expression T_ANDOP expression           { $$.ast.expr_node = mknode_and($1.ast.expr_node, $3.ast.expr_node);   }
                    | expression T_RELOP expression
                    {
                        if (strcmp($2, ".gt.") == 0) {
                            $$.ast.expr_node = mknode_gt($1.ast.expr_node, $3.ast.expr_node);
                        } else if (strcmp($2, ".ge.") == 0) {
                            $$.ast.expr_node = mknode_ge($1.ast.expr_node, $3.ast.expr_node);
                        } else if (strcmp($2, ".lt.") == 0) {
                            $$.ast.expr_node = mknode_lt($1.ast.expr_node, $3.ast.expr_node);
                        } else if (strcmp($2, ".le.") == 0) {
                            $$.ast.expr_node = mknode_le($1.ast.expr_node, $3.ast.expr_node);
                        } else if (strcmp($2, ".ne.") == 0) {
                            $$.ast.expr_node = mknode_ne($1.ast.expr_node, $3.ast.expr_node);
                        } else if (strcmp($2, ".eq.") == 0) {
                            $$.ast.expr_node = mknode_eq($1.ast.expr_node, $3.ast.expr_node);
                        }
                    }
                    | expression T_ADDOP expression           { $$.ast.expr_node = mknode_plus($1.ast.expr_node, $3.ast.expr_node);  }
                    | expression T_MULOP expression           { $$.ast.expr_node = mknode_mul($1.ast.expr_node, $3.ast.expr_node);   }
                    | expression T_DIVOP expression           { $$.ast.expr_node = mknode_div($1.ast.expr_node, $3.ast.expr_node);   }
                    | expression T_POWEROP expression         { $$.ast.expr_node = mknode_pow($1.ast.expr_node, $3.ast.expr_node);   }
                    | T_NOTOP expression                      { $$.ast.expr_node = mknode_not($2.ast.expr_node);                     }
                    | T_ADDOP expression                      { $$.ast.expr_node = mknode_psign($2.ast.expr_node);                   }
                    | variable                                { $$.ast.expr_node = $1.ast.expr_node; $$.v.type = $1.t;               }
                    | constant                                { $$.ast.expr_node = $1.ast.expr_node;                                 }
                    | T_LPAREN expression T_RPAREN            { $$.ast.expr_node = $2.ast.expr_node;                                 }
                    | T_LENGTH T_LPAREN expression T_RPAREN   { $$.ast.expr_node = $3.ast.expr_node;                                 }
                    ;

goto_statement      : T_GOTO label   { $$.ast.expr_node = mkleaf_int($2.integer); }
                    | T_GOTO T_ID T_COMMA T_LPAREN labels T_RPAREN
                    {
                        list_t *id = NULL;
                        id = context_check(my_hashtable, scope, $2);
                        $$.ast.expr_node = mknode_comma(mkleaf_id(id),
                                                        mknode_paren(NULL,
                                                                     $5.ast.expr_node)
                                                       );
                    }
                    ;

labels              : labels T_COMMA label  { $$.ast.expr_node = mknode_comma($1.ast.expr_node, mkleaf_int($3.integer)); }
                    | label                 { $$.ast.expr_node = mkleaf_int($1.integer);                                 }
                    ;

if_statement        : T_IF T_LPAREN expression T_RPAREN if_labels           { $$.ast.cmd_node = mkcmd_arithmetic_if(mknode_if_labels($3.ast.expr_node, $5.ast.expr_node)); }
                    | T_IF T_LPAREN expression T_RPAREN simple_statement    { $$.ast.cmd_node = mkcmd_simple_if($3.ast.expr_node, $5.ast.cmd_node);                        }
                    | T_IF error expression T_RPAREN simple_statement       { yyerror("Missing '('"); yyerrok;                                                             }
                    | T_IF T_LPAREN expression error simple_statement       { yyerror("Missing ')'"); yyerrok;                                                             }
                    ;

if_labels           : label T_COMMA label T_COMMA label   { $$.ast.expr_node = mknode_comma(mkleaf_int($1.integer), mknode_comma(mkleaf_int($3.integer), mkleaf_int($5.integer))); }

subroutine_call     : T_CALL variable       { $$.ast.expr_node = $2.ast.expr_node; }
                    ;

io_statement        : T_READ read_list      { $$.ast.expr_node = $2.ast.expr_node; }
                    | T_WRITE write_list    { $$.ast.expr_node = $2.ast.expr_node; }
                    ;

read_list           : read_list T_COMMA read_item     { $$.ast.expr_node = mknode_comma($1.ast.expr_node, $3.ast.expr_node); }
                    | read_item                       { $$.ast.expr_node = $1.ast.expr_node;                                 }
                    ;

read_item           : variable     { $$.ast.expr_node = $1.ast.expr_node; }
                    | T_LPAREN read_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN
                    {
                        list_t *id = context_check(my_hashtable, scope, $4);
                        $$.ast.expr_node = mknode_comma(mknode_paren(NULL, $2.ast.expr_node), mknode_assign(mkleaf_id(id), $6.ast.expr_node));
                    }
                    ;

iter_space          : expression T_COMMA expression                       { $$.ast.expr_node = mknode_comma($1.ast.expr_node, $3.ast.expr_node);                                 }
                    | expression T_COMMA expression T_COMMA expression    { $$.ast.expr_node = mknode_comma($1.ast.expr_node, mknode_comma($3.ast.expr_node, $5.ast.expr_node)); }
                    ;

/* step                : T_COMMA expression
                    | %empty { }
                    ; */

write_list          : write_list T_COMMA write_item    { $$.ast.expr_node = mknode_comma($1.ast.expr_node, $3.ast.expr_node); }
                    | write_item                       { $$.ast.expr_node = $1.ast.expr_node;                                 }
                    ;

write_item          : expression
                    | T_LPAREN write_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN
                    {
                        list_t *id = context_check(my_hashtable, scope, $4);
                        $$.ast.expr_node = mknode_comma(mknode_paren(NULL, $2.ast.expr_node), mknode_assign(mkleaf_id(id), $6.ast.expr_node));
                    }
                    ;

compound_statement  : branch_statement    { $$ = $1; }
                    | loop_statement      { $$ = $1; }
                    ;

branch_statement    : T_IF T_LPAREN expression T_RPAREN T_THEN body tail    { $$.ast.cmd_node = mkcmd_if($3.ast.expr_node, $6.ast.cmd_node, $7.ast.cmd_node); }
                    ;

tail                : T_ELSE body T_ENDIF                                   { $$.ast.cmd_node = $2.ast.cmd_node;                                              }
                    | T_ENDIF
                    ;

loop_statement      : T_DO T_ID T_ASSIGN iter_space body T_ENDDO
                    {
                        list_t *id = context_check(my_hashtable, scope, $2);
                        $$.ast.cmd_node = mkcmd_loop(mknode_assign(mkleaf_id(id), $4.ast.expr_node), $5.ast.cmd_node);
                    }
                    ;

subprograms         : subprograms subprogram
                    | %empty { }
                    ;

subprogram          : { scope++; /*put*/ } header { scope--; /* do not pop anything */ } body T_END
                    ;

header              : type T_FUNCTION T_ID T_LPAREN formal_parameters T_RPAREN
                    {
                        curr = install(my_hashtable, scope, $1, C_variable, $3);
                        if (curr == NULL) {                                 /* lookup returned null */
                            curr = context_check(my_hashtable, scope, $3);  /* return the node i just put */

                            curr->is_function = 1;          /* recognise id as function */

                            /* functions should have at least 1 parameter */
                            if ($5 != NULL) {
                                curr->id_info.params = $5;
                            } else {
                                ERROR(stderr, "No arguments to function: %s declaration", curr->str);
                                /* SEM_ERROR = 1; */
                            }
                        }
                    }
                    | T_SUBROUTINE T_ID T_LPAREN formal_parameters T_RPAREN
                    {
                        curr = install(my_hashtable, scope, TY_unknown, C_unknown, $2);  /* subroutines do not return sth */

                        if (curr == NULL) {                 /* κοίτα την επιστρεφόμενη null */
                            curr = context_check(my_hashtable, scope, $2);       /* επιστροφή κόμβου i */
                            curr->is_function = 2;          /* αναγνώρισε id σαν υποπρόγραμμα */

                            /* τα υποπρογράμματα μπορούν να μην έχουν παραμέτρους */
                            curr->id_info.params = $4;
                        }
                    }
                    | T_SUBROUTINE T_ID
                    {
                        curr = install(my_hashtable, scope, TY_unknown, C_unknown, $2); /* τα υποπρογράμματα δεμ επιστρέφουν κάτι */

                        if (curr == NULL) {                   /* κοίτα την επιστρεφόμενη null */
                            curr = context_check(my_hashtable, scope, $2);       /* επιστροφή κόμβου i */
                            curr->is_function = 2;          /* αναγνώρισε id σαν υποπρόγραμμα */

                            /* τα υποπρογράμματα μπορούν να μην έχουν παραμέτρους */
                            curr->id_info.params = NULL;
                        }
                    }
                    ;

formal_parameters   : type vars T_COMMA formal_parameters
                    {
                        struct params_t *curr_pl;

                        curr_pl = $4;

                        printf("\nVARS %s \n",$2);
                        /* επεξεργασία κάθε αναγνωριστικού στο string */
                        pch = strtok ($2,"%");
                        while (pch != NULL) {
                            curr = lookup_identifier(my_hashtable, pch, scope);
                            curr->type = $1;    /* το αναγν δηλώνετε εδώ */
                            /* Προσθήκη την πληροφοριά των παραμέτρων σε λίστα */
                            /* Αξιολόγηση :: κατά τιμή ή κατα αναφορά */
                            /* εαβ id string, array η list ---> αξιολόγηση κατα αναφορά */
                            if ( curr->type == TY_string || curr->cat == C_array)
                                curr_pl = insert_params(curr_pl, $1, 1, pch);
                            else    /* αλλιώς κατα τιμή  */
                                curr_pl = insert_params(curr_pl, $1, 0, pch);

                            pch = strtok (NULL, "%");
                        }

                        free($2);
                        $$ = curr_pl;
                        curr_pl = NULL;     /* ! ο pointer πρέπει να ξανά αρχικοποιηθεί για την επόμενη επανάληψη*/
                    }
                    | type vars
                    {
                        struct params_t *curr_pl;

                        printf("\nVARS %s \n",$2);

                        /* επεξεργασία κάθε αναγνωριστικού στο string */
                        pch = strtok ($2,"%");
                        while (pch != NULL) {
                            curr = lookup_identifier(my_hashtable, pch, scope);
                            curr->type = $1;        /* το αναγν δηλώνετε εδώ */
                            /* Προσθήκη την πληροφοριά των παραμέτρων σε λίστα */
                            /* Αξιολόγηση :: κατά τιμή ή κατα αναφορά */
                            /* εαν id string, array η list ---> αξιολόγηση κατα αναφορά */
                            if( curr->type == TY_string || curr->cat == C_array)
                                curr_pl = insert_params(curr_pl, $1, 1, pch);
                            else    /* αλλιώς κατα τιμή  */
                                curr_pl = insert_params(curr_pl, $1, 0, pch);
                            pch = strtok (NULL, "%");
                        }

                        /* δώσε διέυθυνση της λίστας */
                        $$ = curr_pl;
                        free($2);
                        curr_pl = NULL;     /* ! : ο poimter πρέπει να ξανα αρχικοποιηθεί για την επόμενη επανάληψη */
                    }
                    ;

%%