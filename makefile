ALL = parser
YACC = yacc
LEX = flex
CC = cc
OBJS = lex.yy.o y.tab.o structs.o symtable.o semacheck.o
LIBS = -lfl

all: $(ALL)

lex.yy.c: tokenizer.l
	$(LEX) $^

y.tab.c y.tab.h: parser.y
	$(YACC) -d $^

parser: $(OBJS)
	$(CC) $^ $(LIBS) -o parser

lex.yy.o: lex.yy.c y.tab.h structs.h
y.tab.o: y.tab.c symtable.h structs.h semacheck.h

structs.o: structs.c structs.h
symtable.o: symtable.c symtable.h structs.h
semacheck.o: semacheck.c semacheck.h symtable.h structs.h 

.PHONY: clean
clean:
	-rm $(OBJS) $(ALL)
	-rm y.tab.c y.tab.h lex.yy.c
