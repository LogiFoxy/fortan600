#ifndef UTILS_H
#define UTILS_H

#include <stddef.h>

#define BLOCK_SIZE 256

#define CHECK_ERROR(BUFF, MSG) \
    if ((BUFF) == NULL)        \
    {                          \
        perror(MSG);           \
        return EXIT_FAILURE;   \
    }

void print_token(int token);
void print_error(const char *error_msg);

enum rconst_type
{
    normal,
    decimal_point,
    exponent,
    hex,
    bin,
    error
};

int str_to_int(char *str);
void str_tolower(char *str);
int str_check_type(char *str);
int char_to_dec(char c, int base);
double str_base_to_double(char *str, double base);
double str_to_double(char *str);

struct string_buffer
{
    char *string;
    size_t allocated_size;
};

int string_buffer_init(struct string_buffer *buffer);
void string_buffer_destroy(struct string_buffer *buffer);
int string_buffer_concat_string(struct string_buffer *buffer, char *yytext);

#endif
