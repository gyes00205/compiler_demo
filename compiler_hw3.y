/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;
    list table[50];
    int isArray;
    int curLevel;
    int curAddress;
    int isUndefined;
    int lookupAddress;
    int cmpNum;
    int HAS_ERROR;
    int isAssign;
    int reg1isArray;
    int falseNum[100];
    int forlevel[100];
    int exitNum;
    int forNum;
    FILE *fp;
    char* lookupType;
    char* expValue;
    int regAdr1, regAdr2;
    int isRight;
    int isFirst = 0;
    char *regType1, *regType2;
    void yyerror (char const *s)
    {
        HAS_ERROR = 1;
        printf("error:%d: %s\n", yylineno, s);
    }

    void yyerrorCondition (char const *s)
    {
        HAS_ERROR = 1;
        printf("error:%d: %s\n", yylineno+1, s);
    }

    void yyerrorUndefined(char const *s)
    {
        HAS_ERROR = 1;
        printf("error:%d: %s\n", yylineno+1, s);
    }
    /* Symbol table function - you can add new function if needed. */
    static void create_symbol(int level);
    static void insert_symbol(int level, char *name, char *type, int isArray, int init);
    static void lookup_symbol(int level, char *name);
    static void dump_symbol(int level);
    static void check_invalid_operation(char* type1, char* op, char* type2);
    static void check_condition(char* type);
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    bool b_val;
    /* ... */
}

/* Token without return */
%token VAR
%token INT FLOAT BOOL STRING
%token INC DEC
%token GEQ LEQ EQL NEQ
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token LAND LOR
%token NEWLINE
%token PRINT PRINTLN IF ELSE FOR
/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <b_val> BOOL_LIT
%token <s_val> IDENT

/* Nonterminal with return, which need to sepcify type */
// %type <type> Type TypeName ArrayType

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList     { dump_symbol(curLevel); }
;

StatementList
    : StatementList Statement
    | Statement
;

Statement
    : DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    | Block NEWLINE
    | IfStmt NEWLINE
    | ForStmt NEWLINE
    | PrintStmt NEWLINE
    | NEWLINE
;

DeclarationStmt
    : VAR IDENT Type    { insert_symbol(curLevel, $<s_val>2, $<s_val>3, isArray, 0); }
    | VAR IDENT Type  '='  Expression 
    { 
        insert_symbol(curLevel, $<s_val>2, $<s_val>3, isArray, 1); 
    }
;

Type
    : TypeName  { $<s_val>$ = $<s_val>1; isArray = 0; }
    | ArrayType { $<s_val>$ = $<s_val>1; isArray = 1; }
;

TypeName
    : INT   { $<s_val>$ = strdup("int32"); }
    | FLOAT { $<s_val>$ = strdup("float32"); }
    | STRING    { $<s_val>$ = strdup("string"); }
    | BOOL  { $<s_val>$ = strdup("bool"); }
;

SimpleStmt
    : AssignmentStmt
    | ExpressionStmt
    | IncDecStmt
;

AssignmentStmt
    : Expression_Left  assign_op Expression   
    { 
        check_invalid_operation($<s_val>1, $<s_val>2, $<s_val>3); 
        // printf("%s\n", $<s_val>2); 
        if(reg1isArray == 1){
            if(strcmp($<s_val>2, "ASSIGN")==0){
                if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0){
                    fprintf(fp, "iastore\n");
                }
                else if(strcmp($<s_val>1, "float32")==0){
                    fprintf(fp, "fastore\n");
                }
                else if(strcmp($<s_val>1, "string")==0){
                    fprintf(fp, "aastore\n");
                }
            }
        }
        else{
            if(strcmp($<s_val>2, "ASSIGN")==0){
                if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0){
                    fprintf(fp, "istore %d\n", regAdr1);
                }
                else if(strcmp($<s_val>1, "float32")==0){
                    fprintf(fp, "fstore %d\n", regAdr1);
                }
                else if(strcmp($<s_val>1, "string")==0){
                    fprintf(fp, "astore %d\n", regAdr1);
                }
            }
            else {
                if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0){
                    fprintf(fp, "iload %d\n", regAdr1);
                }
                else if(strcmp($<s_val>1, "float32")==0){
                    fprintf(fp, "fload %d\n", regAdr1);
                }
                else {
                    fprintf(fp, "aload %d\n", regAdr1);
                }
                fprintf(fp, "swap\n");
                if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0){
                    fprintf(fp, "i");
                }
                else if(strcmp($<s_val>1, "float32")==0){
                    fprintf(fp, "f");
                }
                else {
                    fprintf(fp, "a");
                }
                if(strcmp($<s_val>2, "ADD_ASSIGN")==0){
                    fprintf(fp, "add\n");
                }
                else if(strcmp($<s_val>2, "SUB_ASSIGN")==0){
                    fprintf(fp, "sub\n");
                }
                else if(strcmp($<s_val>2, "MUL_ASSIGN")==0){
                    fprintf(fp, "mul\n");
                }
                else if(strcmp($<s_val>2, "QUO_ASSIGN")==0){
                    fprintf(fp, "div\n");
                }
                else{
                    fprintf(fp, "rem\n");
                }
                if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0){
                    fprintf(fp, "istore %d\n", regAdr1);
                }
                else if(strcmp($<s_val>1, "float32")==0){
                    fprintf(fp, "fstore %d\n", regAdr1);
                }
                else if(strcmp($<s_val>1, "string")==0){
                    fprintf(fp, "astore %d\n", regAdr1);
                }
            }
        }
        reg1isArray = 0;
    }
;

assign_op
    : '='   { $<s_val>$ = strdup("ASSIGN"); }
    | advance_assign_op
;

advance_assign_op
    : ADD_ASSIGN    { $<s_val>$ = strdup("ADD_ASSIGN"); }
    | SUB_ASSIGN    { $<s_val>$ = strdup("SUB_ASSIGN"); }
    | MUL_ASSIGN    { $<s_val>$ = strdup("MUL_ASSIGN"); }
    | QUO_ASSIGN    { $<s_val>$ = strdup("QUO_ASSIGN"); }
    | REM_ASSIGN    { $<s_val>$ = strdup("REM_ASSIGN"); }
;

ExpressionStmt
    : Expression
;

IncDecStmt
    : Expression  INC   
    { 
        // printf("%s\n", "INC"); 
        fprintf(fp, "%s %d\n", ($<s_val>1[0]=='i')? "ldc 1\niadd\nistore":"ldc 1.0\nfadd\nfstore", lookupAddress); 
    }
    | Expression  DEC   
    { 
        // printf("%s\n", "DEC"); 
        fprintf(fp, "%s %d\n", ($<s_val>1[0]=='i')? "ldc 1\nisub\nistore":"ldc 1.0\nfsub\nfstore", lookupAddress); 
    }
;

Block
    : '{' { curLevel++;} StatementList '}'  { dump_symbol(curLevel); curLevel--; }
;

Block_IF
    : '{' { curLevel++;} StatementList '}'  
    {  
        fprintf(fp, "goto L_if_exit%d\n", exitNum);
        fprintf(fp, "L_if_false%d%d:\n", curLevel, falseNum[curLevel]++);
        dump_symbol(curLevel); curLevel--;
    }
;

Block_ELSE
    : '{' { curLevel++;} StatementList '}'
    {  
        fprintf(fp, "goto L_if_exit%d\n", exitNum);
        dump_symbol(curLevel); curLevel--;
    }

IfStmt
    : IF Condition_IF Block_IF { fprintf(fp, "L_if_exit%d:\n", exitNum++); }
    | IF Condition_IF Block_IF ELSE IfStmt 
    | IF Condition_IF Block_IF ELSE Block_ELSE  { fprintf(fp, "L_if_exit%d:\n", exitNum++); }
;

Condition_IF
    : Expression
    {
        check_condition($<s_val>1);
        fprintf(fp, "ifeq L_if_false%d%d\n", curLevel+1, falseNum[curLevel+1]);
        
    }
;

Condition_FOR
    : Expression    
    { 
        check_condition($<s_val>1);
        fprintf(fp, "ifeq L_for_exit%d%d%d\n", curLevel+1, forlevel[curLevel+1],forNum++);
    }
;

Condition_FOR_CLAUSE
    : Expression    
    { 
        check_condition($<s_val>1);
        fprintf(fp, "goto L_for_first%d%d%d\n",curLevel+1, forlevel[curLevel+1], forNum);
        fprintf(fp, "L_for_second%d%d%d:\n", curLevel+1, forlevel[curLevel+1], forNum);
    }
;

ForStmt
    : FOR_BEGIN Condition_FOR Block_FOR
    | FOR_BEGIN ForClause Block_FOR_CLAUSE 
;

ForClause
    : InitStmt ';' {fprintf(fp, "L_for_begin%d%d%d:\n", curLevel+1, forlevel[curLevel+1],++forNum); } Condition_FOR_CLAUSE ';' PostStmt 
    {
        fprintf(fp, "goto L_for_begin%d%d%d\n",curLevel+1, forlevel[curLevel+1], forNum);
        fprintf(fp, "L_for_first%d%d%d:\n",curLevel+1, forlevel[curLevel+1], forNum);
        fprintf(fp, "ifeq L_for_exit%d%d%d\n", curLevel+1, forlevel[curLevel+1],forNum);
    }
;

FOR_BEGIN
    : FOR   {fprintf(fp, "L_for_begin%d%d%d:\n",curLevel+1, forlevel[curLevel+1], forNum);  }
;

Block_FOR
    : '{' { curLevel++;} StatementList '}'  
    {  
        forNum--;
        fprintf(fp, "goto L_for_begin%d%d%d\n",curLevel, forlevel[curLevel], forNum);
        fprintf(fp, "L_for_exit%d%d%d:\n",curLevel, forlevel[curLevel], forNum);
        forlevel[curLevel]++;
        dump_symbol(curLevel); curLevel--;
    }
;

Block_FOR_CLAUSE
    : '{' { curLevel++; forNum++; } StatementList '}'  
    {
        forNum--;
        fprintf(fp, "goto L_for_second%d%d%d\n",curLevel, forlevel[curLevel], forNum);
        fprintf(fp, "L_for_exit%d%d%d:\n",curLevel, forlevel[curLevel], forNum);
        forlevel[curLevel]++;
        dump_symbol(curLevel); curLevel--;
        forNum--;
    }
;

InitStmt
    : SimpleStmt
;

PostStmt
    : SimpleStmt
;

PrintStmt
    : PRINT '(' Expression ')'      
    { 
        if($<s_val>3[0]=='b'){
            // printf("PRINT bool\n");
            fprintf(fp, "ifne L_cmp_%d\n", cmpNum);
            fprintf(fp, "ldc \"false\"\n");
            fprintf(fp, "goto L_cmp_%d\n", cmpNum+1);
            fprintf(fp, "L_cmp_%d", cmpNum); fprintf(fp, ":\n");
            fprintf(fp, "ldc \"true\"\n");
            fprintf(fp, "L_cmp_%d", cmpNum+1); fprintf(fp, ":\n");  
            cmpNum +=2 ;
        } 
        fprintf(fp, "getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        fprintf(fp, "swap\n");
        if($<s_val>3[0]=='s'){
            // printf("PRINT string\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }
        if($<s_val>3[0]=='i'){
            // printf("PRINT int32\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/print(I)V\n");
        }
        if($<s_val>3[0]=='f'){
            // printf("PRINT float32\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/print(F)V\n");
        }
        if($<s_val>3[0]=='b'){
            fprintf(fp, "invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }

    }
    | PRINTLN '(' Expression ')'    
    { 
        if($<s_val>3[0]=='b'){
            // printf("PRINT bool\n");
            fprintf(fp, "ifne L_cmp_%d\n", cmpNum);
            fprintf(fp, "ldc \"false\"\n");
            fprintf(fp, "goto L_cmp_%d\n", cmpNum+1);
            fprintf(fp, "L_cmp_%d", cmpNum); fprintf(fp, ":\n");
            fprintf(fp, "ldc \"true\"\n");
            fprintf(fp, "L_cmp_%d", cmpNum+1); fprintf(fp, ":\n");
            cmpNum += 2;  
        } 
        fprintf(fp, "getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        fprintf(fp, "swap\n");
        if($<s_val>3[0]=='s'){
            // printf("PRINTLN string\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }
        if($<s_val>3[0]=='i'){
            // printf("PRINTLN int32\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/println(I)V\n");
        }
        if($<s_val>3[0]=='f'){
            // printf("PRINTLN float32\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/println(F)V\n");
        }
        if($<s_val>3[0]=='b'){
            // printf("PRINTLN bool\n");
            fprintf(fp, "invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        } 
    }
;

ArrayType
    : '[' Expression ']' Type   { $<s_val>$ = $<s_val>4; }
;

Expression
    : Expression1   { $<s_val>$ = $<s_val>1; }
    | Expression LOR Expression1   
    { 
        check_invalid_operation($<s_val>1, "LOR", $<s_val>3); 
        // printf("%s\n", "LOR"); 
        $<s_val>$ = strdup("bool"); 
        fprintf(fp, "ior\n");
    }
;

Expression1
    : Expression2   { $<s_val>$ = $<s_val>1; }
    | Expression1 LAND Expression2 
    { 
        check_invalid_operation($<s_val>1, "LAND", $<s_val>3); 
        // printf("%s\n", "LAND"); 
        $<s_val>$ = strdup("bool"); 
        fprintf(fp, "iand\n");
    }
;

Expression2
    : Expression3   { $<s_val>$ = $<s_val>1; }
    | Expression2 cmp_op Expression3 
    { 
        // printf("%s\n", $<s_val>2); 
        $<s_val>$ = strdup("bool");
        fprintf(fp, "%s\n", ($<s_val>1[0]=='i')? "isub":"fcmpl");
        if(strcmp($<s_val>2, "EQL")==0){ fprintf(fp, "ifeq "); }
        else if(strcmp($<s_val>2, "NEQ")==0){ fprintf(fp, "ifne "); }
        else if(strcmp($<s_val>2, "LSS")==0){ fprintf(fp, "iflt "); }
        else if(strcmp($<s_val>2, "LEQ")==0){ fprintf(fp, "ifle "); }
        else if(strcmp($<s_val>2, "GTR")==0){ fprintf(fp, "ifgt "); }
        else if(strcmp($<s_val>2, "GEQ")==0){ fprintf(fp, "ifge "); }
        fprintf(fp, "L_cmp_%d\n", cmpNum);
        fprintf(fp, "iconst_0\n");
        fprintf(fp, "goto L_cmp_%d\n", cmpNum+1);
        fprintf(fp, "L_cmp_%d", cmpNum); fprintf(fp, ":\n");
        fprintf(fp, "iconst_1\n");
        fprintf(fp, "L_cmp_%d", cmpNum+1); fprintf(fp, ":\n");
        cmpNum += 2;
    }
;

Expression3
    : Expression4   { $<s_val>$ = $<s_val>1; }
    | Expression3 add_op Expression4 
    { 
        check_invalid_operation($<s_val>1, $<s_val>2, $<s_val>3); 
        // printf("%s\n", $<s_val>2);
        fprintf(fp, "%c%s\n", $<s_val>1[0], $<s_val>2);
    }
;

Expression4
    : UnaryExpr { $<s_val>$ = $<s_val>1; }
    | Expression4 mul_op UnaryExpr 
    { 
        check_invalid_operation($<s_val>1, $<s_val>2, $<s_val>3); 
        // printf("%s\n", $<s_val>2); 
        if(strcmp($<s_val>2, "rem")==0){
            fprintf(fp, "irem\n");
        }
        else{
            fprintf(fp, "%c%s\n", $<s_val>1[0], $<s_val>2);
        }
    }
;

UnaryExpr
    : PrimaryExpr   { $<s_val>$ = $<s_val>1; } 
    | unary_op UnaryExpr    
    { 
        // printf("%s\n", $<s_val>1); 
        $<s_val>$ = $<s_val>2; 
        if(strcmp($<s_val>1, "neg")==0){
            fprintf(fp, "%cneg\n", $<s_val>2[0]);
        }
        else if(strcmp($<s_val>1, "NOT")==0){
            fprintf(fp, "iconst_1\nixor\n");
        } 
    }
;

unary_op
    : '+'   { $<s_val>$ = strdup("POS"); }
    | '-'   { $<s_val>$ = strdup("neg"); }
    | '!'   { $<s_val>$ = strdup("NOT"); }
;

PrimaryExpr
    : Operand   { $<s_val>$ = $<s_val>1; }
    | IndexExpr
    | ConversionExpr
;

IndexExpr
    : PrimaryExpr '[' Expression ']'    
    {
        if(strcmp($<s_val>1, "int32")==0 || strcmp($<s_val>1, "bool")==0) {
            fprintf(fp, "iaload\n"); 
        }
        else if(strcmp($<s_val>1, "float32")==0){
            fprintf(fp, "faload\n"); 
        }
        else if(strcmp($<s_val>1, "string")==0){
            fprintf(fp, "aaload\n");
        }
    }
;

ConversionExpr
    : Type '(' Expression ')'   
    {
        $<s_val>$ = $<s_val>1; 
        // printf("%c to %c\n",($<s_val>3[0] - 32), ($<s_val>1[0] - 32)); 
        fprintf(fp, "%c2%c\n", $<s_val>3[0], $<s_val>1[0]); 
    
    } 
;

Operand
    : Literal   { $<s_val>$ = $<s_val>1; }
    | IDENT     { lookup_symbol(curLevel, $<s_val>1); $<s_val>$ = strdup(lookupType); }
    | '(' Expression ')'    { $<s_val>$ = $<s_val>2; }
;

cmp_op
    : EQL   { $<s_val>$ = strdup("EQL"); }
    | NEQ   { $<s_val>$ = strdup("NEQ"); }
    | '<'   { $<s_val>$ = strdup("LSS"); }
    | LEQ   { $<s_val>$ = strdup("LEQ"); }
    | '>'   { $<s_val>$ = strdup("GTR"); }
    | GEQ   { $<s_val>$ = strdup("GEQ"); }
;

add_op
    : '+'   { $<s_val>$ = strdup("add"); }
    | '-'   { $<s_val>$ = strdup("sub"); }
;

mul_op
    : '*'   { $<s_val>$ = strdup("mul"); }
    | '/'   { $<s_val>$ = strdup("div"); }
    | '%'   { $<s_val>$ = strdup("rem"); }
;



Literal
    : INT_LIT    { /*printf("INT_LIT %d\n", $1);*/ $<s_val>$ = strdup("int32_lit"); fprintf(fp, "ldc %d\n", $1); }
    | FLOAT_LIT  { /*printf("FLOAT_LIT %f\n", $1);*/ $<s_val>$ = strdup("float32_lit"); fprintf(fp, "ldc %f\n", $1);}
    | BOOL_LIT   { /*printf("%s\n", ($1)? "TRUE":"FALSE");*/ $<s_val>$ = strdup("bool_lit"); fprintf(fp, "iconst_%d\n", $1); }
    | STRING_LIT { /*printf("STRING_LIT %s\n", $1);*/ $<s_val>$ = strdup("string_lit"); fprintf(fp, "ldc \"%s\"\n", $1);}
;

Expression_Left
    : Operand_L   { $<s_val>$ = $<s_val>1; }
    | PrimaryExpr '[' Expression ']'  { reg1isArray = 1; regAdr1 = lookupAddress; }
;


Operand_L
    : Literal   { $<s_val>$ = $<s_val>1; }
    | IDENT     { isAssign = 1; lookup_symbol(curLevel, $<s_val>1); $<s_val>$ = strdup(lookupType);  regAdr1 = lookupAddress; }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    for(int i=0;i<100;i++){
        falseNum[i] = 0;
        forlevel[i] = 0;
    }
    isFirst = 0;
    forNum = 0;
    isRight = 0;
    reg1isArray = 0;
    isAssign = 0;
    expValue = strdup("");
    curAddress = 0;
    curLevel = 0;
    isUndefined = 0;
    lookupAddress = -1;
    cmpNum = 0;
    exitNum = 0;
    HAS_ERROR = 0;
    create_symbol(curLevel);
    yylineno = 0;
    fp = fopen("hw3.j", "w");
    fprintf(fp, ".source hw3.j\n");
    fprintf(fp, ".class public Main\n");
    fprintf(fp, ".super java/lang/Object\n");
    fprintf(fp, ".method public static main([Ljava/lang/String;)V\n");
    fprintf(fp, ".limit stack 100\n");
    fprintf(fp, ".limit locals 100\n");

    yyparse();

	// printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    fprintf(fp, "return\n");
    fprintf(fp, ".end method\n");
    if(HAS_ERROR==1){
        remove("hw3.j");
    }
    return 0;
}

static void create_symbol(int level) {
    for(int i=0;i<50;i++){
        table[i].size = 0;
        table[i].head = NULL;
        table[i].tail = NULL;
    }
}

static void insert_symbol(int level, char *name, char *type, int isArray, int init) {
    list_data* current = table[level].head;
    int exist = 0;
    char errorMsg[1000];
    strcpy(errorMsg, "");
    while(current != NULL){
        if(strcmp(current->name, name)==0){
            exist = 1;
            break;
        }
        else{
            current = current->next;
        }
    }
    if(exist==0){
        list_data* node = (list_data*)malloc(sizeof(list_data));
        node->index = table[level].size;
        node->name = strdup(name);
        node->type = (isArray==0)? strdup(type):strdup("array");;
        node->address = curAddress++;
        node->lineno = yylineno;
        node->element_type = (isArray==0)? strdup("-"):strdup(type);
        node->next = NULL;
        if(table[level].size==0){
            table[level].head = node;
            table[level].tail = node;
        }
        else{
            table[level].tail->next = node;
            table[level].tail = node;
        }
        table[level].size++;
        if(isArray==1){
            fprintf(fp, "newarray ");
            if(type[0]=='i'){ fprintf(fp, "int\n"); }
            else if(type[0]=='f'){ fprintf(fp, "float\n"); }
            else if(type[0]=='s'){ fprintf(fp, "string\n"); }
            else if(type[0]=='b'){ fprintf(fp, "bool\n"); }
            fprintf(fp, "astore %d\n", node->address);
        }
        else if(strcmp(type, "int32")==0){
            if(init == 0){
                fprintf(fp, "ldc 0\n");
            }
            fprintf(fp, "istore %d\n", node->address);
        }
        else if(strcmp(type, "float32")==0){
            if(init == 0){
                fprintf(fp, "ldc 0.0\n");
            }
            fprintf(fp, "fstore %d\n", node->address);
        }
        else if(strcmp(type, "string")==0){
            if(init == 0){
                fprintf(fp, "ldc \"\"\n");
            }
            fprintf(fp, "astore %d\n", node->address);
        }
        else if(strcmp(type, "bool")==0){
            if(init == 0){
                fprintf(fp, "ldc 0");
            }
            fprintf(fp, "istore %d\n", node->address);
        }    
        
        // printf("> Insert {%s} into symbol table (scope level: %d)\n", name, level);
    }
    else{
        sprintf(errorMsg, "%s redeclared in this block. previous declaration at line %d", name, current->lineno);
        yyerror(errorMsg);
    }
}

static void lookup_symbol(int level, char *name) {
    list_data* current;
    int exist = 0;
    char errorMsg[1000];
    strcpy(errorMsg, "");
    while(level>=0){
        current = table[level].head;
        while(current != NULL){
            if(strcmp(current->name, name)==0){
                exist = 1;
                break;
            }
            else{
                current = current->next;
            }
        }
        if(exist==1)
            break;
        level--;
    }
    if(exist==1){
        isArray = (strcmp("array", current->type)==0)? 1:0;
        lookupType = (strcmp("array", current->type)==0)? strdup(current->element_type):strdup(current->type);
        lookupAddress = current->address;
        if(isAssign==0){
            if(strcmp(current->type, "int32")==0){
                fprintf(fp, "iload %d\n", current->address);
            }
            else if(strcmp(current->type, "float32")==0){
                fprintf(fp, "fload %d\n", current->address);
            }
            else if(strcmp(current->type, "bool")==0){
                fprintf(fp, "iload %d\n", current->address);
            }
            else if(strcmp(current->type, "string")==0 || strcmp(current->type, "array")==0){
                fprintf(fp, "aload %d\n", current->address);
            }
        }
        else{
            isAssign = 0;
        }
        // printf("IDENT (name=%s, address=%d)\n", name, current->address);
    }
    else{
        lookupType = strdup("");
        isUndefined = 1;
        sprintf(errorMsg, "undefined: %s", name);
        yyerrorUndefined(errorMsg);
    }
}

static void dump_symbol(int level) {
    list_data* prev = NULL;
    list_data* current = table[level].head;
    // printf("> Dump symbol table (scope level: %d)\n", level);
    // printf("%-10s%-10s%-10s%-10s%-10s%s\n",
    //     "Index", "Name", "Type", "Address", "Lineno", "Element type");
    while(current != NULL){
        // printf("%-10d%-10s%-10s%-10d%-10d%s\n",
        //         current->index, current->name, current->type, current->address, current->lineno, current->element_type);
        prev = current;
        current = current->next;
        free(prev);
    }
    table[level].size = 0;
    table[level].head = NULL;
    table[level].tail = NULL;
}

static void check_invalid_operation(char* type1, char* op, char* type2) {
    char errorMsg[1000];
    strcpy(errorMsg, "");
    if(strcmp(op, "ASSIGN")==0 || strcmp(op, "ADD_ASSIGN")==0 || strcmp(op, "SUB_ASSIGN")==0 || strcmp(op, "MUL_ASSIGN")==0 || strcmp(op, "QUO_ASSIGN")==0 || strcmp(op, "REM_ASSIGN")==0){
        if(strcmp(type1, "int32_lit")==0){
            yyerror("cannot assign to int32");
            return;
        }
        if(strcmp(type1, "float32_lit")==0){
            yyerror("cannot assign to float32");
            return;
        }
        if(strcmp(type1, "string_lit")==0){
            yyerror("cannot assign to string");
            return;
        }
        if(strcmp(type1, "bool_lit")==0){
            yyerror("cannot assign to bool");
            return;
        }
    }
    if(strcmp(type1, "")==0 || strcmp(type2, "")==0)
        return;

    if(type1[0]=='i') type1 = strdup("int32");
    if(type1[0]=='f') type1 = strdup("float32");
    if(type1[0]=='s') type1 = strdup("string");
    if(type1[0]=='b') type1 = strdup("bool");

    if(type2[0]=='i') type2 = strdup("int32");
    if(type2[0]=='f') type2 = strdup("float32");
    if(type2[0]=='s') type2 = strdup("string");
    if(type2[0]=='b') type2 = strdup("bool");

    if(strcmp("REM", op)==0){
        if( strcmp(type1,"int32")!=0 && strcmp(type1,"int32_lit")!=0){
            
            sprintf(errorMsg, "invalid operation: (operator REM not defined on %s)", type1);
            yyerror(errorMsg);
        }
        if( strcmp(type2,"int32")!=0 && strcmp(type2,"int32_lit")!=0){

            sprintf(errorMsg, "invalid operation: (operator REM not defined on %s)", type2);
            yyerror(errorMsg);
        }
    }
    else if(strcmp("LAND", op)==0 || strcmp("LOR", op)==0) {
        if( strcmp(type1,"bool")!=0 && strcmp(type1,"bool_lit")!=0){
            sprintf(errorMsg, "invalid operation: (operator %s not defined on %s)", op, type1);
            yyerror(errorMsg);
        }
        if( strcmp(type2,"bool")!=0 && strcmp(type2,"bool_lit")!=0){
            sprintf(errorMsg, "invalid operation: (operator %s not defined on %s)", op, type2);
            yyerror(errorMsg);
        }
        
    }
    else if(type1[0]!=type2[0]){
        sprintf(errorMsg, "invalid operation: %s (mismatched types %s and %s)", op, type1, type2);
        yyerror(errorMsg);
    }
    else{
        
    }
}

static void check_condition(char* type) {
    char errorMsg[1000];
    strcpy(errorMsg, "");
    if(strcmp(type, "bool")!=0 && strcmp(type, "bool_lit")!=0){
        if(type[0]=='i') type = strdup("int32");
        if(type[0]=='f') type = strdup("float32");
        if(type[0]=='s') type = strdup("string");
        if(type[0]=='b') type = strdup("bool");
        sprintf(errorMsg, "non-bool (type %s) used as for condition", type);
        yyerrorCondition(errorMsg);
    }
}
