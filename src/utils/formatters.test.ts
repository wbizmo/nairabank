import { describe,expect,it } from "vitest"
import { maskAccountNumber,percentage } from "./formatters"
describe("financial formatters",()=>{it("masks account numbers",()=>expect(maskAccountNumber("0192837465")).toBe("**** 7465"));it("clamps percentages",()=>expect(percentage(120,100)).toBe(100))})
