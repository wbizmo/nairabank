import type { Icon } from "@phosphor-icons/react"
import { ArrowsLeftRight,Car,ForkKnife,Lightning,ShoppingBag,Wallet } from "@phosphor-icons/react"
import type { Transaction,TransactionCategory } from "../../domain/dashboard"
import { formatNaira,formatTransactionDate } from "../../utils/formatters"
const icons:Record<TransactionCategory,Icon>={Shopping:ShoppingBag,Transport:Car,Bills:Lightning,Transfers:ArrowsLeftRight,Food:ForkKnife,Income:Wallet}
export function TransactionList({transactions}:{transactions:Transaction[]}){return <section className="nb-panel" aria-labelledby="transactions-title"><h2 id="transactions-title" className="nb-panel-title">Recent transactions</h2>{transactions.map((tx)=>{const TxIcon=icons[tx.category],credit=tx.kind==="credit";return <article key={tx.id} className="nb-tx-row"><div className="nb-tx-left"><div className="nb-tx-icon"><TxIcon size={16}/></div><div><div className="nb-tx-name">{tx.merchant}</div><div className="nb-tx-sub">{tx.category} · {formatTransactionDate(tx.date)}</div></div></div><span className={`nb-tx-amt${credit?" credit":""}`}>{credit?"+":"-"}{formatNaira(tx.amount)}</span></article>})}</section>}
