import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"
import { App } from "./App"
describe("App foundation",()=>{it("renders brand and loading state",()=>{render(<App/>);expect(screen.getByText("naira")).toBeInTheDocument();expect(screen.getByLabelText("Loading dashboard")).toBeInTheDocument()})})
