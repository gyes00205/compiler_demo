#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
/* struct ... */
typedef struct list_data{
    int index;
    char *name;
    char *type;
    int address;
    int lineno;
    char *element_type;
    struct list_data *next;
} list_data;

typedef struct{
    int size;
    list_data *head;
    list_data *tail;
} list;

#endif /* COMMON_H */