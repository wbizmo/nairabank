import type { DashboardData } from "../domain/dashboard"
import { getJson } from "./httpClient"
const DEFAULT_DELAY_MS=1100
function wait(ms:number,signal?:AbortSignal){return new Promise<void>((resolve,reject)=>{const timer=window.setTimeout(resolve,ms);signal?.addEventListener("abort",()=>{window.clearTimeout(timer);reject(new DOMException("The request was aborted","AbortError"))},{once:true})})}
export async function fetchDashboard(signal?:AbortSignal):Promise<DashboardData>{const params=new URLSearchParams(window.location.search);const parsed=Number(params.get("delay")??DEFAULT_DELAY_MS);await wait(Number.isFinite(parsed)?Math.max(0,parsed):DEFAULT_DELAY_MS,signal);if(params.get("simulateError")==="true")throw new Error("We could not load your account right now.");return getJson<DashboardData>("/dashboard.json",signal)}
