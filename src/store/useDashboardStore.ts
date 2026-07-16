import { create } from "zustand"
import type { DashboardData } from "../domain/dashboard"
import { fetchDashboard } from "../services/dashboardService"
export type RequestStatus="idle"|"loading"|"success"|"error"
interface State{status:RequestStatus;data:DashboardData|null;error:string|null;balanceVisible:boolean;activeTab:string;load:()=>Promise<void>;retry:()=>Promise<void>;toggleBalance:()=>void;setActiveTab:(tab:string)=>void}
let controller:AbortController|null=null
export const useDashboardStore=create<State>((set,get)=>({status:"idle",data:null,error:null,balanceVisible:true,activeTab:"home",load:async()=>{controller?.abort();controller=new AbortController();set({status:"loading",error:null});try{const data=await fetchDashboard(controller.signal);set({data,status:"success",error:null})}catch(error){if(error instanceof DOMException&&error.name==="AbortError")return;set({status:"error",error:error instanceof Error?error.message:"Unexpected dashboard error"})}},retry:async()=>get().load(),toggleBalance:()=>set((s)=>({balanceVisible:!s.balanceVisible})),setActiveTab:(activeTab)=>set({activeTab})}))
