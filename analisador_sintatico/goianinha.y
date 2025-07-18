%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../includes/ast.h"

struct ASTNode;

extern int yylex();
extern int yylineno;
void yyerror(const char *s);
extern ASTNode* ast_raiz;
%}

%union {
    int valor_int;
    char* texto;
    struct ASTNode* no;
}

%token PROGRAMA TK_INT TK_CAR RETORNE LEIA ESCREVA NOVALINHA SE ENTAO SENAO ENQUANTO EXECUTE
%token <texto> ID
%token <texto> STRINGCONST
%token <texto> CARCONST
%token <texto> INTCONST

%token MAIS MENOS MULT DIV IGUAL DIFERENTE MENOR MAIOR MAIORIGUAL MENORIGUAL ATRIBUICAO
%token OU E
%token ABREPAR FECHAPAR ABRECHAVE FECHACHAVE VIRGULA PONTOVIRGULA

%type <no> Programa DeclFuncVar DeclProg Tipo DeclVar DeclFunc ListaParametros ListaParametrosCont Bloco ListaDeclVar ListaComando Comando Expr OrExpr AndExpr EqExpr DesigExpr AddExpr MulExpr UnExpr PrimExpr ListExpr

%start Programa

%%

Programa: DeclFuncVar DeclProg
    {
        ast_raiz = criar_no(NODE_PROGRAMA, yylineno, NULL, 0, TIPO_VOID, 2, $1, $2);
        (yyval.no) = ast_raiz;
    }
;

DeclFuncVar: Tipo ID DeclVar PONTOVIRGULA DeclFuncVar
    {
        ASTNode* atual = criar_no(NODE_DECLVAR, yylineno, $2, 0, $1->tipo_dado, 1, $3);
        (yyval.no) = $5 ? criar_no(NODE_LISTA, yylineno, NULL, 0, TIPO_UNKNOWN, 2, atual, $5) : atual;
    }
| Tipo ID DeclFunc DeclFuncVar
    {
        ASTNode* atual = criar_no(NODE_FUNCAO, yylineno, $2, 0, $1->tipo_dado, 1, $3);
        (yyval.no) = $4 ? criar_no(NODE_LISTA, yylineno, NULL, 0, TIPO_UNKNOWN, 2, atual, $4) : atual;
    }
| %empty
    {
        (yyval.no) = NULL;
    }
;

DeclProg: PROGRAMA Bloco
    {
        (yyval.no) = criar_no(NODE_BLOCO, yylineno, strdup("programa"), 0, TIPO_VOID, 1, $2);
    }
;

Tipo: TK_INT
    { (yyval.no) = criar_no(NODE_ID, yylineno, strdup("int"), 0, TIPO_INT, 0); }
| TK_CAR
    { (yyval.no) = criar_no(NODE_ID, yylineno, strdup("car"), 0, TIPO_CAR, 0); }
;

DeclVar: VIRGULA ID DeclVar
    {
        ASTNode* idNode = criar_no(NODE_ID, @2.first_line, $2, 0, TIPO_UNKNOWN, 0);
        (yyval.no) = criar_no(NODE_LISTA, yylineno, NULL, 0, TIPO_UNKNOWN, 2, idNode, $3);
    }
| %empty
    {
        (yyval.no) = NULL;
    }
;

DeclFunc: ABREPAR ListaParametros FECHAPAR Bloco
    {
        (yyval.no) = criar_no(NODE_FUNCAO, yylineno, NULL, 0, TIPO_UNKNOWN, 2, $2, $4);
    }
;

ListaParametros: %empty
    { (yyval.no) = NULL; }
| ListaParametrosCont
    { (yyval.no) = $1; }
;

ListaParametrosCont: Tipo ID
    {
        ASTNode* idNode = criar_no(NODE_ID, @2.first_line, $2, 0, $1->tipo_dado, 0);
        (yyval.no) = criar_no(NODE_LISTA, yylineno, strdup("param_list"), 0, TIPO_UNKNOWN, 1, idNode);
    }
| Tipo ID VIRGULA ListaParametrosCont
    {
        ASTNode* idNode = criar_no(NODE_ID, @2.first_line, $2, 0, $1->tipo_dado, 0);
        (yyval.no) = criar_no(NODE_LISTA, yylineno, strdup("param_list"), 0, TIPO_UNKNOWN, 2, idNode, $4);
    }
;

Bloco: ABRECHAVE ListaDeclVar ListaComando FECHACHAVE
    {
        (yyval.no) = criar_no(NODE_BLOCO, yylineno, NULL, 0, TIPO_VOID, 2, $2, $3);
    }
;

ListaDeclVar: %empty
    { (yyval.no) = NULL; }
| Tipo ID DeclVar PONTOVIRGULA ListaDeclVar
    {
        ASTNode* idNode = criar_no(NODE_ID, @2.first_line, $2, 0, $1->tipo_dado, 0);
        ASTNode* decl = criar_no(NODE_DECLVAR, yylineno, NULL, 0, $1->tipo_dado, 2, idNode, $3);
        (yyval.no) = criar_no(NODE_LISTA, yylineno, NULL, 0, TIPO_UNKNOWN, 2, decl, $5);
    }
;

ListaComando: Comando
    {
        (yyval.no) = criar_no(NODE_LISTA, yylineno, NULL, 0, TIPO_UNKNOWN, 1, $1);
    }
| ListaComando Comando
    {
        (yyval.no) = criar_no(NODE_LISTA, @2.first_line, NULL, 0, TIPO_UNKNOWN, 2, $1, $2);
    }
;

Comando: PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup(";"), 0, TIPO_VOID, 0);
    }
| Expr PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("expr;"), 0, TIPO_VOID, 1, $1);
    }
| RETORNE Expr PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("retorne"), 0, TIPO_VOID, 1, $2);
    }
| LEIA ID PONTOVIRGULA
    {
        ASTNode* idNode = criar_no(NODE_ID, @2.first_line, $2, 0, TIPO_UNKNOWN, 0);
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("leia"), 0, TIPO_VOID, 1, idNode);
    }
| ESCREVA Expr PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("escreva"), 0, TIPO_VOID, 1, $2);
    }
| ESCREVA STRINGCONST PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("escreva_str"), 0, TIPO_VOID, 0);
    }
| NOVALINHA PONTOVIRGULA
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("novalinha"), 0, TIPO_VOID, 0);
    }
| SE ABREPAR Expr FECHAPAR ENTAO Comando
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("se"), 0, TIPO_VOID, 2, $3, $6);
    }
| SE ABREPAR Expr FECHAPAR ENTAO Comando SENAO Comando
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("se_senao"), 0, TIPO_VOID, 3, $3, $6, $8);
    }
| ENQUANTO ABREPAR Expr FECHAPAR EXECUTE Comando
    {
        (yyval.no) = criar_no(NODE_CMD, yylineno, strdup("enquanto"), 0, TIPO_VOID, 2, $3, $6);
    }
| Bloco
    {
        (yyval.no) = $1;
    }
;

Expr: OrExpr
    { (yyval.no) = $1; }
| ID ATRIBUICAO Expr
    {
        ASTNode* idNode = criar_no(NODE_ID, yylineno, $1, 0, TIPO_UNKNOWN, 0);
        (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("="), 0, TIPO_UNKNOWN, 2, idNode, $3);
    }
;

OrExpr: OrExpr OU AndExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("ou"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| AndExpr
    { (yyval.no) = $1; }
;

AndExpr: AndExpr E EqExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("e"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| EqExpr
    { (yyval.no) = $1; }
;

EqExpr: EqExpr IGUAL DesigExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("=="), 0, TIPO_UNKNOWN, 2, $1, $3); }
| EqExpr DIFERENTE DesigExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("!="), 0, TIPO_UNKNOWN, 2, $1, $3); }
| DesigExpr
    { (yyval.no) = $1; }
;

DesigExpr: DesigExpr MENOR AddExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("<"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| DesigExpr MAIOR AddExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup(">"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| DesigExpr MAIORIGUAL AddExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup(">="), 0, TIPO_UNKNOWN, 2, $1, $3); }
| DesigExpr MENORIGUAL AddExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("<="), 0, TIPO_UNKNOWN, 2, $1, $3); }
| AddExpr
    { (yyval.no) = $1; }
;

AddExpr: AddExpr MAIS MulExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("+"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| AddExpr MENOS MulExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("-"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| MulExpr
    { (yyval.no) = $1; }
;

MulExpr: MulExpr MULT UnExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("*"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| MulExpr DIV UnExpr
    { (yyval.no) = criar_no(NODE_EXPR, @2.first_line, strdup("/"), 0, TIPO_UNKNOWN, 2, $1, $3); }
| UnExpr
    { (yyval.no) = $1; }
;

UnExpr: MENOS PrimExpr
    { (yyval.no) = criar_no(NODE_EXPR, yylineno, strdup("-"), 0, TIPO_UNKNOWN, 1, $2); }
| '!' PrimExpr
    { (yyval.no) = criar_no(NODE_EXPR, yylineno, strdup("!"), 0, TIPO_UNKNOWN, 1, $2); }
| PrimExpr
    { (yyval.no) = $1; }
;

PrimExpr: ID ABREPAR ListExpr FECHAPAR
    {
        ASTNode* idNode = criar_no(NODE_ID, yylineno, $1, 0, TIPO_UNKNOWN, 0);
        (yyval.no) = criar_no(NODE_EXPR, yylineno, strdup("call"), 0, TIPO_UNKNOWN, 2, idNode, $3);
    }
| ID ABREPAR FECHAPAR
    {
        ASTNode* idNode = criar_no(NODE_ID, yylineno, $1, 0, TIPO_UNKNOWN, 0);
        (yyval.no) = criar_no(NODE_EXPR, yylineno, strdup("call"), 0, TIPO_UNKNOWN, 1, idNode);
    }
| ID
    {
        (yyval.no) = criar_no(NODE_ID, yylineno, $1, 0, TIPO_UNKNOWN, 0);
    }
| CARCONST
    {
        (yyval.no) = criar_no(NODE_CONST, yylineno, NULL, $1[0], TIPO_CAR, 0);
    }
| INTCONST
    {
        (yyval.no) = criar_no(NODE_CONST, yylineno, NULL, atoi($1), TIPO_INT, 0);
    }
| ABREPAR Expr FECHAPAR
    {
        (yyval.no) = $2;
    }
;

ListExpr: Expr
    {
        (yyval.no) = criar_no(NODE_LISTA, yylineno, strdup("arg_list"), 0, TIPO_UNKNOWN, 1, $1);
    }
| ListExpr VIRGULA Expr
    {
        (yyval.no) = criar_no(NODE_LISTA, @2.first_line, strdup("arg_list"), 0, TIPO_UNKNOWN, 2, $1, $3);
    }
;

%%

void yyerror(const char *s) {
    printf("ERRO: %s linha %d\n", s, yylineno);
}
