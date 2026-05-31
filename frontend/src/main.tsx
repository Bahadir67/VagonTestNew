import { createRoot } from "react-dom/client";
import App from "./App";
import "./global.css";

const container = document.getElementById("root");
if (!container) throw new Error("#root not found");

// No StrictMode: the imported design runs imperative DOM script once on mount;
// StrictMode's double-invoke would run it twice.
createRoot(container).render(<App />);
