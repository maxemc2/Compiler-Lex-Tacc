#pragma once
#include "structs.h"
extern int curScopeLevel;

enum SymbolKind {
  SymbolKind_program, SymbolKind_procedure, SymbolKind_parameter,
  SymbolKind_variable, SymbolKind_constant, SymbolKind_loopVar
};

struct Args
{
  struct Type *type;
  struct Args *PREV;
  struct Args *NEXT;
};

struct SymTableEntry
{
    char *name;
    enum SymbolKind kind;
    struct Type *type;
    int level;    
    bool constant;
    struct Args *args;
    struct SymTableEntry *PREV;
    struct SymTableEntry *NEXT;
};

struct SymbolStack
{
    struct SymTableEntry *node; //current node
    struct SymbolStack *NEXT; // the next
};

struct Args* getArgs();

//SymTableEntry
void deleteArgs(struct Args* args);
void deleteEntry(struct SymTableEntry* entry);
struct SymTableEntry* deleteSymbolEntry(struct SymTableEntry* entry);

//SymbolStack
void clearStack(struct SymbolStack** top);
void assignType(struct Type *, bool );
void assignTypeByEnum(enum TypeEnum type, bool constant);
void popSymbol(struct SymbolStack** top);
void pushSymbol(struct SymbolStack** top, struct SymTableEntry *node);

//symboltable
int hash(const char *name);
void addVar(char *name, enum SymbolKind kind);
void initSymbolTable();
struct SymTableEntry* getSymbol(const char *name);
int searchSymbolPos(const char *name);
void deleteSymbolTable();
void PrintSymbolEntry(const struct SymTableEntry *cur);
void PrintSymbolTable();
void nextScope();
void prevScope();