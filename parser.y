%{
#include "symtable.h"
#include "semacheck.h"
#include <stdio.h>
#include <stdlib.h>

extern int linenum;
extern FILE *yyin;
extern int yylex(void);

#define Trace(t)  { printf(t); }

struct SymTableEntry *curFunc = NULL;
%}

/* Terminal */
%union
{
    bool flag;
    char *name;
    enum TypeEnum typeEnum;
    enum Operator oper;    
    struct Constant literal;
    struct Type *type;
    struct Expr *expr;
    struct ExprList args;
    struct Args *funcArgs;
}
/* Keywords */
//rename to BEGIN_ because BEGIN is a keyword in lex
%token BEGIN_
//type
%token INTEGER STRING BOOLEAN FLOAT CONSTANT
//boolean
%token TRUE FALSE
//conditional
%token IF ELSE DO THEN FOR LOOP WHILE BREAK CONTINUE 
//print
%token PRINT PRINTLN
%token EXIT CASE IN OF READ CHARACTER 
//block
%token PROGRAM PROCEDURE DECLARE RETURN END

//operation
%token ASSIGN
%right ASSIGN
%left AND OR
%right NOT
%left '<' '>' LE GE NE '='
%left '+' '-'
%left '*' '/'
%right UMINUS
%left '!'

%nonassoc LOWER_THEN_INDEX
%nonassoc '['

%token <name> ID

// literals
%token<literal> LIT_INT LIT_STR LIT_REAL

/* nonterminal */
%type<literal> literalConstant
%type<type> type var_assignType procedure_return
%type<typeEnum> type_keyword
%type<args> arg_list arguments
%type<funcArgs> para_declares
%type<oper> mul_op add_op rel_op
%type<expr> reference_variable function_invoc
%type<expr> prior_expr factor term expression relation_expr boolean_factor boolean_term boolean_expr

%%
/*** Program ***/
program:    
        PROGRAM ID 
        {
            addVar($2, SymbolKind_program);
            nextScope();
        }
        var_const_declares
        { 
            Trace("Reducing to var_const_declares\n");
        }
        procedure_declares
        { 
            Trace("Reducing to procedure_declares\n");
        }
        BEGIN_
        statements
        END
        {
            Trace("Reducing to programbody\n");
        }
        END ID
        {
            Trace("Reducing to program\n");
        }
        ;

block: 
        {  
            nextScope(); 
        }
        var_const_declares 
        BEGIN_
        statements
        END ';'
        {
            prevScope();
            Trace("Reducing to block\n"); 
        }
        ;

/*** Procedures ***/
procedure_declares:
        /* empty */ { Trace("No procedure!\n"); }
        | procedure_declare 
        | procedure_declares procedure_declare
        ;

procedure_declare:
        PROCEDURE ID 
        {
            addVar($2, SymbolKind_procedure);
            curFunc = getSymbol($2);
            nextScope();
        }
        para_declares
        {
            curFunc->args = $4;
            Trace("Procedure's parameter declaration!\n");
        }
        procedure_return
        {
            curFunc->type = $6;
        }
        {
            //the arg of the procedure has the same scope as the content 
            curScopeLevel--; 
        }
        block END ID ';'
        {
            Trace("Reducing to procedure\n");
            curFunc = NULL;
        }
        ;

procedure_return:
        /* Empty */ { $$ = createType(Type_VOID); }
        | RETURN type {$$ = $2;}
        ;

para_declares:
        /* Empty */ 
        { 
            $$ = NULL;
            Trace("No parameters!\n"); 
        }
        | '(' para_declare ')'
        {
            $$ = getArgs();
        }
        ;

para_declare:
        /* Empty */   { Trace("No parameters!\n"); }
        | var_assignType { Trace("add new parameter\n"); }
        | para_declare ';' var_assignType 
        ;

/*** Statements ***/
statements:
        /* empty */
        | statements statement
        ;

statement:
        simple_stmt
        | procedure_call { Trace("Reducing to procedure_call\n");  }
        | return_stmt
        | conditional_stmt { Trace("Reducing to conditional_stmt\n");  }
        | while_stmt  { Trace("Reducing to  while_stmt\n");  }
        | for_stmt  { Trace("Reducing to for_stmt\n");  }
        ;

simple_stmt:
        reference_variable ASSIGN boolean_expr ';' 
        { 
            assignCheck($1, $3);
            deleteExpr($3);
            Trace("Reducing to simple stmt (Assign statement)\n"); 
        }
        | print_keyword boolean_expr ';'
        { 
            printCheck($2);
            deleteExpr($2);
            Trace("print statement\n"); 
        }
        | READ reference_variable ';'
        {
            deleteExpr($2);
        }
        ;

block_or_simple:
        block { Trace("Reducing to block_or_simple (block)\n"); }
        | simple_stmt { Trace("Reducing to block_or_simple (simple)\n"); }
        ;

return_stmt: 
        RETURN boolean_expr ';'
        {
            returnCheck($2, curFunc->type);
            deleteExpr($2);
        }
        | RETURN ';'
        {
            if(curFunc->type != Type_VOID) semanticError("Procedure %s should have the return value!\n", curFunc->name);
        }
        ;

procedure_call: function_invoc ';' 
        { 
            deleteExpr($1);
        }
        ;

/* Function Invocation */
function_invoc: 
        ID '(' arg_list ')'
        {
            Trace("Reducing to function_invoc\n");
            $$ = createFuncExpr($1, $3.first);
            functionCheck($$);
        }
        ;

arg_list:
        /* no arguments */ { initExprList(&$$); }
        | arguments
        ;

arguments:
        boolean_expr
        {
            initExprList(&$$);
            addToExprList(&$$, $1);
        }
        | arguments ',' boolean_expr
        {
            addToExprList(&$1, $3); 
            $$ = $1;
        }
        ;

/* Conditional */
conditional_stmt:
                IF condition THEN block_or_simple ELSE block_or_simple END IF ';'
                | IF condition THEN block_or_simple END IF ';'
                ;

condition:
        boolean_expr 
        {
            conditionCheck($1, "if");
            deleteExpr($1);
        }
        ;

/* Loop */
while_stmt:
        WHILE boolean_expr 
        {
            conditionCheck($2, "while");
            deleteExpr($2);
        }
        LOOP
        block_or_simple
        END LOOP ';'
        {
            Trace("End While Loop\n");
        }
        ;

for_stmt:
        FOR '(' reference_variable IN literalConstant '.' '.' literalConstant ')'
        {
            if($5.type != Type_INT || $8.type != Type_INT) semanticError("for loop range should be integer");
            //forCheck($5.integer, $8.integer); 
            deleteExpr($3);
        }
        LOOP block_or_simple END LOOP ';'
        {
           // if ($<boolVal>3) removeLoopVar(); 
            Trace("End For Loop\n");
        }
        ;

print_keyword:
        PRINT
        | PRINTLN
        ;

/*** Expression ***/
/* Relation */
relation_expr:
        expression { Trace("Reducing to relation_expr\n"); }
        | relation_expr rel_op expression
        {
            $$ = createExpr($2, $1, $3);
            relOpCheck($$);
        }
        ;
rel_op:
        '<' { $$ = Op_LESS; }
        | LE { $$ = Op_LEQUAL; }
        | '=' { $$ = Op_EQUAL; }
        | GE { $$ = Op_GEQUAL; }
        | '>' { $$ = Op_GREATER; }
        | NE { $$ = Op_NOTEQUAL; }
        ;

/* Multiple and Divide */
term:
        factor { Trace("Reducing to term\n"); }
        | term mul_op factor
        {
            $$ = createExpr($2, $1, $3);
            arithOpCheck($$);
        }
        ;
mul_op:
        '*' { Trace("Reducing to mul_op\n"); $$ = Op_MULTIPLY;}
        | '/' { Trace("Reducing to mul_op\n"); $$ = Op_DIVIDE;}
        ;

/* Plus and Minus */
expression:
        term { Trace("Reducing to expression\n"); }
        | expression add_op term
        {
            Trace("Reducing to expression by binary element\n");
            $$ = createExpr($2, $1, $3);
            arithOpCheck($$);
        }
        ;
add_op:
        '+' { Trace("Reducing to add_op\n"); $$ = Op_PLUS; }
        | '-' { Trace("Reducing to add_op\n"); $$ = Op_MINUS; }
        ;

reference_variable:
        ID %prec LOWER_THEN_INDEX
        { 
            $$ = createVarExpr($1);  
            varTypeCheck($$); 
        }
        | ID '[' boolean_expr ']'
        {
            $$ = createExpr(Op_INDEX, createVarExpr($1), $3);
            arrayTypeCheck($$);
            Trace("Reducing to a array element ref\n");
        }
        ;
        
prior_expr:
        '(' boolean_expr ')' 
        { 
            $$ = $2; 
            Trace("Reducing to prior expression\n");
        }
        | reference_variable { Trace("Reducing to prior expression by var ref\n"); }
        | function_invoc
        ;


factor:
        prior_expr { Trace("Reducing to factor\n"); }
        | literalConstant
        { 
            Trace("Reducing to factor by literalConstant\n");
            $$ = createLitExpr($1);
        }
        | '-' prior_expr
        {
            $$ = createExpr(Op_UMINUS, $2, NULL);
            unaryOpCheck($$);
            Trace("Unary minus expression\n");
        }
        ;

/* Boolean */
boolean_factor:
        relation_expr { Trace("Reducing to boolean factor\n"); }
        | NOT boolean_factor
        {
            $$ = createExpr(Op_NOT, $2, NULL);
            unaryOpCheck($$);
        }
        ;

boolean_term:
        boolean_factor { Trace("Reducing to boolean_term\n"); }
        | boolean_term AND boolean_factor
        {
            $$ = createExpr(Op_AND, $1, $3);
            boolOpCheck($$);
        }
        ;

boolean_expr:
        boolean_term { Trace("Reducing to boolean_expr\n"); }
        | boolean_expr OR boolean_term
        {  
            $$ = createExpr(Op_OR, $1, $3);
            boolOpCheck($$);
        }
        ;


/*** Declaration ***/
var_const_declares:
        /* Empty */  { Trace("No var_const_declares!\n"); }
        | DECLARE declaration
        ;

declaration:
        /* Empty */
        | declaration var_declare 
        | declaration constVar_declare { }
        ;

var_declare:
        var_assignType ';' 
        { 
            deleteType($1);
            Trace("Reducing to var_declare\n");
        }
        | identifier_list  ASSIGN  boolean_expr ';'  
        { 
            if($3->type == NULL)
            {
                semanticError("init error(left-side and right-side have different type)");
                assignTypeByEnum(Type_VOID, false);
            }
            else
            {
                assignType($3->type, false);
            }
            deleteExpr($3);
            Trace("Reducing to var_declare\n");
        }
        | var_assignType ASSIGN boolean_expr ';' 
        {
            if($3->type == NULL || $1->type != $3->type->type)
            {
                semanticError("init error(left-side and right-side have different type)");
            }
            deleteType($1);
            deleteExpr($3);
            Trace("Reducing to var_declare\n");
        }
        ;

var_assignType:
        identifier_list ':' type
        {
            assignType($3, false);
            $$ = $3;
            Trace("Reducing to var_assignType\n");
        }
        ;

constVar_declare:
        identifier_list  ':' CONSTANT ASSIGN boolean_expr ';' 
        { 
            if($5->type == NULL)
            {
                semanticError("LSH is VOID type");
                assignTypeByEnum(Type_VOID, true);
            }
            assignType($5->type, true);
        }
        | identifier_list ':' CONSTANT ':' type ASSIGN boolean_expr ';' 
        { 
            assignType($5, true);
            if($7->type == NULL || $5->type != $7->type->type)
            {
                semanticError("init error(left-side and right-side have different type)");
            }
            deleteType($5);
            deleteExpr($7);
            Trace("Reducing to constVar_declare\n");
        }
        ;

// Multiple variable on same line
identifier_list:
         ID { addVar($1, SymbolKind_variable); }
         | identifier_list ',' ID { addVar($3, SymbolKind_variable); }
         ;

/*** Type And Constant ***/
type:
        type_keyword %prec LOWER_THEN_INDEX
        { 
            $$ = malloc(sizeof(struct Type));
            $$->type = $1;
            $$->itemType = NULL;
        }
        | type_keyword '[' literalConstant ']'
        {
            if ($3.type == Type_INT && $3.integer > 0)
            {
                $$ = malloc(sizeof(struct Type));
                $$->type = Type_ARRAY;
                $$->itemType = malloc(sizeof(struct ArrayItems));
                $$->itemType->type = $1;
                $$->itemType->size = $3.integer;
            }
            else
            {
                semanticError("Array should be defined by positive integer");
            }
        }
        ;

type_keyword:
        BOOLEAN  { $$ = Type_BOOL; }
        | INTEGER  { $$ = Type_INT; }
        | FLOAT  { $$ = Type_REAL; }
        | STRING  { $$ = Type_STR;}
        ;

literalConstant:
        LIT_INT { Trace("literal_integer\n");}
        | '-' LIT_INT 
        { 
            $$ = $2;
            $$.integer = -($$.real);
            Trace("Minus integer\n");
        }

        | LIT_STR
        | LIT_REAL
        | '-' LIT_REAL 
        {
            $$ = $2;
            $$.real = -($$.real);
            Trace("Minus real\n");
        } 
        | TRUE { $$.type = Type_BOOL; $$.boolean = true; }
        | FALSE { $$.type = Type_BOOL; $$.boolean = false; }
        ;
%%

int yyerror(char *msg)
{
    fprintf(stderr, "%s\n", msg);
    exit(-1);
}

int main(int argc, char *argv[])
{
    initSymbolTable();
    
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }

    yyin = fopen(argv[1], "r");         /* open input file */
    if(yyin)
    {
        printf("Open file success!\n");
    }
    else
    {
        printf("Open file fail!\n");
        return 0;
    }
    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
    {
        yyerror("Parsing error!");     /* syntax error */
    }
    PrintSymbolTable();
    //clear
    deleteSymbolTable();
}

