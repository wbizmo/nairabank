import { useEffect } from "react"
import { useDashboardStore } from "../store/useDashboardStore"
export function useDashboard(){const status=useDashboardStore((s)=>s.status);const data=useDashboardStore((s)=>s.data);const error=useDashboardStore((s)=>s.error);const load=useDashboardStore((s)=>s.load);const retry=useDashboardStore((s)=>s.retry);useEffect(()=>{if(status==="idle")void load()},[load,status]);return{status,data,error,retry}}
