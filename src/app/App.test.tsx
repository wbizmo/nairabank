import { render,screen,waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach,describe,expect,it,vi } from "vitest"
import App from "./App"
const response={ok:true,json:async()=>({account:{holderName:"Amara Chukwu",accountNumber:"0192837465",balance:482350.75,dailyLimit:500000,dailyUsed:76500,monthlyLimit:5000000,monthlyUsed:1875200},trend:[40,44,42],transactions:[],categories:[]})}
beforeEach(()=>{vi.stubGlobal("fetch",vi.fn().mockResolvedValue(response));window.history.replaceState({},"","/?delay=0")})
describe("dashboard",()=>{it("loads account data",async()=>{render(<App/>);expect(await screen.findByText(/₦482,350.75/)).toBeInTheDocument()});it("provides simulated action feedback",async()=>{const user=userEvent.setup();render(<App/>);await screen.findByText(/₦482,350.75/);await user.click(screen.getByRole("button",{name:"Send"}));await waitFor(()=>expect(screen.getByRole("status")).toHaveTextContent(/simulated/i))})})
