#pragma once
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

extern char *OpName[];

enum TypeEnum {
    Type_BOOL, Type_INT, Type_REAL, Type_STR, Type_ARRAY, Type_VOID, Type_NONE
};

enum Operator {
  Op_NONE, Op_OR, Op_AND, Op_NOT, //logic
  Op_PLUS, Op_MINUS,  Op_MULTIPLY, Op_DIVIDE, //arithmetic
  Op_LESS, Op_LEQUAL, Op_GREATER, Op_GEQUAL, Op_EQUAL, Op_NOTEQUAL, Op_DIVIDEEQ, //compare
  Op_INDEX, Op_UMINUS, Op_FUNC,
  Op_LIT,
  Op_VAR
};

struct Type{
  enum TypeEnum type;
  // For Array Type
  struct ArrayItems *itemType;
};

struct Constant{
  enum TypeEnum type;
  union {
    char *str;
    bool boolean;
    int integer;
    float real;    
  };
};

struct ArrayItems{
  enum TypeEnum type;
  int size;
};

struct Expr {
  enum Operator op;
  struct Type *type;
  union {
    struct Constant lit;
    struct Expr *args;
    char *name; //handle var
  };
  struct Expr *next;
};

struct ExprList {
  struct Expr *first;
  struct Expr *last;
};

//error report
void semanticError(const char *fmt, ...);

//type 
struct Type *createType(enum TypeEnum type);
void showType(struct Type *type);
void printType(enum TypeEnum type);
struct Type * copyType(struct Type *type);
void deleteType(struct Type *type);
bool isSameType(struct Type *t1, struct Type *t2);
bool canConvertTypeImplicitly(struct Type *from, struct Type *to);
bool isScalarType(struct Type *type);

//expression
struct Expr *createExpr(enum Operator op, struct Expr *op1, struct Expr *op2);
struct Expr *createVarExpr(char *name);
struct Expr *createLitExpr(struct Constant lit);
struct Expr *createFuncExpr(char *name, struct Expr *args);
void deleteExpr(struct Expr *expr);

//parameters
void initExprList(struct ExprList *list);
void addToExprList(struct ExprList *list, struct Expr *expr);

//other
void deleteConst(struct Constant c);