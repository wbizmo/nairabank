export type TransactionKind="credit"|"debit"
export type TransactionStatus="successful"|"pending"|"failed"
export type TransactionCategory="Income"|"Shopping"|"Transport"|"Bills"|"Transfers"|"Food"
export interface Account{holderName:string;accountNumber:string;balance:number;dailyLimit:number;dailyUsed:number;monthlyLimit:number;monthlyUsed:number}
export interface Transaction{id:string;merchant:string;category:TransactionCategory;amount:number;kind:TransactionKind;date:string;status:TransactionStatus}
export interface SpendingCategory{name:Exclude<TransactionCategory,"Income">;value:number;color:string}
export interface DashboardData{account:Account;trend:number[];transactions:Transaction[];categories:SpendingCategory[]}
