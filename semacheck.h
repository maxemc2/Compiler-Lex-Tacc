#pragma once

#include "symtable.h"

//check for assignment
void assignCheck(struct Expr *var, struct Expr *expr);

//check variable type
void varTypeCheck(struct Expr *var);

//check array type
void arrayTypeCheck(struct Expr *arr);

//check if expression is expected type
void returnCheck(struct Expr *expr, struct Type *expected);

//check condition expression part of conditional (if...else) and while statement
void conditionCheck(struct Expr *expr, const char *ifwhile);

//check for loop parameter
void forCheck(int lowerBound, int upperBound);

//check function call
void functionCheck(struct Expr *expr);

//check print and read statements
void printCheck(struct Expr *expr);
void readCheck(struct Expr *expr);

//check arithmetic operators
void unaryOpCheck(struct Expr *expr);
void boolOpCheck(struct Expr *expr);
void arithOpCheck(struct Expr *expr);
void modOpCheck(struct Expr *expr);
void relOpCheck(struct Expr *expr);

