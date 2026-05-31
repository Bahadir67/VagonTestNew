import { useEffect, useRef } from "react";
import rawHtml from "./design/test-kontrol.html?raw";

/**
 * Renders the imported "Test Kontrol" design (single-file HTML+CSS+JS) verbatim
 * inside the React tree: its <style> goes to <head>, its body markup is injected
 * into the host div, and its <script> runs once on mount. This keeps the design
 * pixel-identical; we'll Reactify / wire telemetry incrementally from here.
 */
export default function TestKontrolApp() {
  const hostRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const doc = new DOMParser().parseFromString(rawHtml, "text/html");

    // 1) styles → <head>
    const injected: HTMLStyleElement[] = [];
    doc.querySelectorAll("style").forEach((s) => {
      const el = document.createElement("style");
      el.setAttribute("data-tk", "1");
      el.textContent = s.textContent;
      document.head.appendChild(el);
      injected.push(el);
    });

    // 2) body markup (scripts pulled out so they aren't injected as inert nodes)
    const scripts = Array.from(doc.querySelectorAll("script"));
    scripts.forEach((s) => s.remove());
    host.innerHTML = doc.body.innerHTML;

    // 3) run the design's script(s) against the now-present DOM
    scripts.forEach((s) => {
      try {
        new Function(s.textContent || "")();
      } catch (err) {
        console.error("Test Kontrol script error:", err);
      }
    });

    return () => {
      injected.forEach((el) => el.remove());
      host.innerHTML = "";
    };
  }, []);

  return (
    <div
      ref={hostRef}
      style={{
        height: "100%",
        width: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        overflow: "hidden",
        background: "radial-gradient(1200px 700px at 50% -10%, #3a4655, #232a33 60%, #1b2027 100%)",
      }}
    />
  );
}
