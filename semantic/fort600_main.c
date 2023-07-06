
#include "utils/utils.h"

extern void yyparse();
extern hash_table_t *my_hashtable;
extern struct string_buffer buff;

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("MISSING FILE.\n");
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL)
    {
        perror("COULD NOT OPEN THE FILE.\n");
        return EXIT_FAILURE;
    }

    if ((INPUT_FILE_NAME = malloc(NULL_CHAR_SIZE + strlen(argv[1]))) == NULL)
    {
        perror("fort600: error:");
        exit(EXIT_FAILURE);
    }
    /*error messages */
    strcpy(INPUT_FILE_NAME, argv[1]);

    /* starting my_hashtable (it is founded in parser) */
    my_hashtable = create_hash_table(8); /* fixed size of 8 lists */
    if (my_hashtable == NULL)
    {
        printf("Hash table allocation error\n");
        return -1;
    }

    string_buffer_init(&buff);

    /* starting ΑΣΔ */
    AST_init();

    yyparse();
    printf("==============    Parse Completed   ==============\n\n");

    fclose(yyin);
    string_buffer_destroy(&buff);

    printf("==============    Intermediate Representation  ==============\n");
    print_ast();

    return EXIT_SUCCESS;
}
