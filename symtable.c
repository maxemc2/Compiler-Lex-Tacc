#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#define  SYMTABSIZE 1000

int curScopeLevel;
struct SymTableEntry *symbolTable[SYMTABSIZE];
struct SymbolStack *varList;
struct SymbolStack *declaration;
static char *typeName[] = {"Boolean", "Integer", "Real", "String", "Array", "Void"};
static char *typeKind[] = {"Program", "Procedure", "Parameter", "Variable", "Constant", "LoopVar"};

/*** SymbolEntry ***/
void deleteArgs(struct Args* args)
{
    if(args == NULL) return;

    struct Args* cur;
    cur = args;
    deleteType(cur->type);

    cur = args->NEXT;
    free(args);
    deleteArgs(cur);
}

struct SymTableEntry* deleteSymbolEntry(struct SymTableEntry* entry)
{
    struct SymTableEntry *cur = entry;
    if(cur->name != NULL) free(cur->name);
    deleteType(cur->type);
    deleteArgs(cur->args);
    entry = cur;
    cur = cur->NEXT;
    free(entry);
    return cur;
}

void deleteEntry(struct SymTableEntry* entry)
{
    while(entry) entry = deleteSymbolEntry(entry);
}

/*** Symbolstack ***/
void popSymbol(struct SymbolStack** top)
{
    if(*top)
    {
        struct SymbolStack *tmp = *top;
        (*top) = (*top)->NEXT;
        tmp->node = NULL;
        free(tmp);
    }
}

void pushSymbol(struct SymbolStack** top, struct SymTableEntry *node)
{
    struct SymbolStack *tmp = malloc(sizeof(struct SymbolStack));
    tmp->node = node;
    tmp->NEXT = *top;
    *top = tmp;
}

void clearStack(struct SymbolStack** top)
{
    while(*top) popSymbol(top);
}

//for use type keywords
void assignType(struct Type *type, bool constant)
{
    if(declaration == NULL) return;
    do{
        declaration->node->type = copyType(type);
        declaration->node->constant = constant;
        pushSymbol(&varList, declaration->node);
        popSymbol(&declaration);
    }while(declaration);
}

void assignTypeByEnum(enum TypeEnum type, bool constant)
{
    if(declaration == NULL) return;
    struct Type *tmp = createType(type);
    do{
        declaration->node->type = copyType(tmp);
        declaration->node->constant = constant;
        pushSymbol(&varList, declaration->node);
        popSymbol(&declaration);
    }while(declaration);
    deleteType(tmp);
}

/*** Symboltable ***/
struct Args* getArgs()
{
    struct SymbolStack* top = varList;
    if(top == NULL || top->node->level != curScopeLevel) return NULL;
    struct Args *n = malloc(sizeof(struct Args)), *tmp = n;


    tmp->type = copyType(top->node->type);
    tmp->NEXT = NULL;
    tmp->PREV = NULL;
    top = top->NEXT;
    while(top && top->node->level == curScopeLevel)
    {
        tmp->NEXT = malloc(sizeof(struct Args));
        tmp->NEXT->PREV = tmp;
        tmp = tmp->NEXT;
        tmp->type = copyType(top->node->type);
        tmp->NEXT = NULL;
        top = top->NEXT;
    }
    n = tmp;
    while(tmp)
    {
        tmp->NEXT = tmp->PREV;
        tmp->PREV = NULL;
        tmp = tmp->NEXT;
    }
    return n;
}

void nextScope()
{
    curScopeLevel ++;
    //push all symbol in varList to declaration

    while(declaration)
    {
        pushSymbol(&varList, declaration->node);
        popSymbol(&declaration);
    }
    //printf("Now Scope = %d!\n", curScopeLevel);
    //PrintSymbolTable();
}

void prevScope()
{
    printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
    printf("Discard Var:\n");
    int pos;
    curScopeLevel --;
    while(varList->node->level != curScopeLevel)
    {
        PrintSymbolEntry(varList->node);
        pos = searchSymbolPos(varList->node->name);
        symbolTable[pos] = deleteSymbolEntry(varList->node);
        popSymbol(&varList);
    }
    printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
    PrintSymbolTable();
}

int hash(const char *name)
{
    unsigned long hash = 5381;
    int c;

    while (c = *name++)
        hash = ((hash << 4) + hash) + c;
    
    return ((int)((hash)%SYMTABSIZE));
}

int searchSymbolPos(const char *name)
{
    int c1 = 2, c2= 3, i = 0;
    bool flag = false;
    int pos = hash(name);

    while(symbolTable[pos] != NULL)
    {
        //if two identifier same name
        if(!strcmp(symbolTable[pos]->name, name)) break;
        //quadratic probing
        pos = (pos + c1 * i + c2 * i * i) % SYMTABSIZE;
        i++;
    }
    return pos;
}

struct SymTableEntry* getSymbol(const char *name)
{
    int pos = searchSymbolPos(name);
    if(symbolTable[pos] == NULL) return NULL;
    else return symbolTable[pos];
}

// init symbol table
void initSymbolTable()
{
    for(int i = 0; i< SYMTABSIZE; i++) symbolTable[i] = NULL;
    curScopeLevel = 0;
    varList = NULL;
    declaration = NULL;
}

void deleteSymbolTable()
{
    struct SymTableEntry *tmp = NULL;
    for(int i = 0; i< SYMTABSIZE; i++)
    {
        if(symbolTable[i] != NULL)
        {
            deleteEntry(symbolTable[i]);
            symbolTable[i] = NULL;
        }
    }
    clearStack(&varList);
    clearStack(&declaration);
}

void PrintSymbolEntry(const struct SymTableEntry *cur)
{
    if(cur == NULL) 
    {
        printf("Some Error occur in PrintSymbolEntry!\n");
        return;
    }
    printf("Name: %5s,", cur->name);
    if(cur->type == NULL) printf(" Type: %8s,", "None");
    else printf(" Type: %8s,", typeName[cur->type->type]);   
    printf(" Kind: %9s, Level: %2d  |\n", typeKind[cur->kind],cur->level);
}

void PrintSymbolTable()
{
    printf("--------------------------------------------------------------\n");
    printf("Print SymbolTable: \n");

    struct SymbolStack *top = varList;
    while(top)
    {
        PrintSymbolEntry(top->node);
        top = top->NEXT;
    }
    
    // for(int i = 0, t; i< SYMTABSIZE;i++)
    // {
    //     struct SymTableEntry *cur = symbolTable[i];
    //     while(cur)
    //     {
    //         PrintSymbolEntry(cur);
    //         cur = cur->NEXT;
    //     }
    // }
    printf("--------------------------------------------------------------\n");
}

// Add new identifer
void addVar(char *name, enum SymbolKind kind)
{
    struct SymTableEntry *newVar = malloc(sizeof(struct SymTableEntry));
    newVar->name = name;
    newVar->level = curScopeLevel;
    newVar->kind = kind;
    newVar->type = NULL;
    newVar->constant = false;
    newVar->args = NULL;
    newVar->PREV = NULL;
    newVar->NEXT = NULL;
    int pos = searchSymbolPos(name);

    //if two identifer have same name, then linked them
    if(symbolTable[pos] != NULL)
    {
        if(symbolTable[pos]->level == newVar->level)
        {
            semanticError("redeclaration of name %s", newVar->name);
        }
        newVar->NEXT = symbolTable[pos];
        symbolTable[pos]->PREV = newVar;
    }
    symbolTable[pos] = newVar;
    pushSymbol(&declaration, newVar);
}