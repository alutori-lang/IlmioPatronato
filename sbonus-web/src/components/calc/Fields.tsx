"use client";

import { useId } from "react";
import { formatEuro } from "@/lib/calc/money";

const inputCls =
  "w-full rounded-xl border bg-bg px-3.5 py-3 text-base text-ink placeholder:text-ink-3 focus:outline-none focus:ring-2 focus:ring-[var(--ring)]";

type NumberFieldProps = {
  label: string;
  value: string;
  onChange: (v: string) => void;
  suffix?: string;
  hint?: string;
  error?: string;
  placeholder?: string;
  inputMode?: "decimal" | "numeric";
};

export function NumberField({ label, value, onChange, suffix, hint, error, placeholder, inputMode = "decimal" }: NumberFieldProps) {
  const id = useId();
  const describedBy = [hint && `${id}-hint`, error && `${id}-err`].filter(Boolean).join(" ") || undefined;
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-semibold text-ink">
        {label}
      </label>
      <div className="relative mt-1.5">
        <input
          id={id}
          type="text"
          inputMode={inputMode}
          autoComplete="off"
          value={value}
          placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy}
          maxLength={14}
          className={`${inputCls} ${suffix ? "pr-14" : ""} ${error ? "border-danger" : "border-line focus:border-brand"}`}
        />
        {suffix && <span className="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-sm text-ink-3">{suffix}</span>}
      </div>
      {hint && (
        <p id={`${id}-hint`} className="mt-1.5 text-sm text-ink-3">
          {hint}
        </p>
      )}
      {error && (
        <p id={`${id}-err`} className="mt-1.5 text-sm font-medium text-danger">
          {error}
        </p>
      )}
    </div>
  );
}

export function SelectField<T extends string>({
  label,
  value,
  onChange,
  options,
  hint,
}: {
  label: string;
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: string }[];
  hint?: string;
}) {
  const id = useId();
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-semibold text-ink">
        {label}
      </label>
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value as T)}
        aria-describedby={hint ? `${id}-hint` : undefined}
        className={`${inputCls} mt-1.5 border-line focus:border-brand`}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      {hint && (
        <p id={`${id}-hint`} className="mt-1.5 text-sm text-ink-3">
          {hint}
        </p>
      )}
    </div>
  );
}

export function CheckField({ label, checked, onChange, hint }: { label: string; checked: boolean; onChange: (v: boolean) => void; hint?: string }) {
  const id = useId();
  return (
    <div className="flex items-start gap-3 rounded-xl border border-line bg-bg p-3.5">
      <input
        id={id}
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        aria-describedby={hint ? `${id}-hint` : undefined}
        className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand)]"
      />
      <label htmlFor={id} className="text-[0.95rem] text-ink">
        {label}
        {hint && (
          <span id={`${id}-hint`} className="mt-0.5 block text-sm text-ink-3">
            {hint}
          </span>
        )}
      </label>
    </div>
  );
}

export function CalcForm({ onSubmit, onReset, children, submitLabel = "Calcola" }: { onSubmit: () => void; onReset: () => void; children: React.ReactNode; submitLabel?: string }) {
  return (
    <form
      noValidate
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit();
      }}
      className="space-y-5 rounded-2xl border border-line bg-surface p-5 sm:p-6"
    >
      {children}
      <div className="flex flex-col gap-2 pt-1 sm:flex-row">
        <button type="submit" className="rounded-xl bg-brand px-6 py-3 font-semibold text-brand-ink transition hover:bg-brand-2">
          {submitLabel}
        </button>
        <button type="button" onClick={onReset} className="rounded-xl border border-line px-6 py-3 font-semibold text-ink-2 transition hover:bg-surface-2">
          Ricomincia
        </button>
      </div>
    </form>
  );
}

export function ResultPanel({ titolo, valore, nota, children }: { titolo: string; valore: string; nota?: string; children?: React.ReactNode }) {
  return (
    <section aria-live="polite" aria-label="Risultato" className="animate-rise rounded-2xl border border-accent/30 bg-surface p-5 shadow-sm sm:p-6">
      <p className="text-sm font-semibold uppercase tracking-wide text-accent">{titolo}</p>
      <p className="mt-1 font-display text-4xl font-extrabold tracking-tight text-ink">{valore}</p>
      {nota && <p className="mt-1 text-sm text-ink-3">{nota}</p>}
      {children && <div className="mt-5">{children}</div>}
    </section>
  );
}

export function Righe({ righe }: { righe: { l: string; v: number | string; segno?: "+" | "-"; forte?: boolean }[] }) {
  return (
    <dl className="divide-y divide-line rounded-xl border border-line">
      {righe.map((r) => (
        <div key={r.l} className={`flex items-center justify-between gap-4 px-4 py-2.5 ${r.forte ? "bg-surface-2 font-semibold text-ink" : "text-ink-2"}`}>
          <dt>{r.l}</dt>
          <dd className="shrink-0 tabular-nums">
            {typeof r.v === "number" ? `${r.segno === "-" ? "−" : r.segno === "+" ? "+" : ""}${formatEuro(r.v)}` : r.v}
          </dd>
        </div>
      ))}
    </dl>
  );
}

export function ErrorBox({ msg }: { msg: string }) {
  return (
    <p role="alert" className="rounded-2xl border border-danger/30 bg-danger-soft p-4 font-medium text-danger">
      {msg}
    </p>
  );
}

export function EmptyResult({ testo }: { testo: string }) {
  return <div className="rounded-2xl border border-dashed border-line p-6 text-center text-ink-3">{testo}</div>;
}
