import { useState } from 'react';
import { api } from '../api';

export default function AddPassengerForm({ onCreated }) {
  const [form, setForm] = useState({ name: '', email: '', phone: '' });
  const [result, setResult] = useState(null);
  const [busy, setBusy] = useState(false);

  function handleChange(event) {
    setForm({ ...form, [event.target.name]: event.target.value });
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setBusy(true);
    setResult(null);
    try {
      const passenger = await api.createPassenger(form);
      setResult({ type: 'success', text: `Passenger created with ID ${passenger.passengerId}.` });
      setForm({ name: '', email: '', phone: '' });
      onCreated();
    } catch (err) {
      setResult({ type: 'error', text: err.message });
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form inline" onSubmit={handleSubmit}>
      <label>
        Name
        <input name="name" value={form.name} onChange={handleChange} required />
      </label>
      <label>
        Email
        <input type="email" name="email" value={form.email} onChange={handleChange} required />
      </label>
      <label>
        Phone (10 digits)
        <input name="phone" value={form.phone} onChange={handleChange} required />
      </label>
      <button type="submit" disabled={busy}>{busy ? 'Saving…' : 'Add Passenger'}</button>
      {result && <p className={`message ${result.type}`}>{result.text}</p>}
    </form>
  );
}
