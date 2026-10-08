import { useState } from 'react';
import { api } from '../api';

export default function ReserveSeatForm() {
  const [form, setForm] = useState({ passengerId: '', routeId: '', seatNumber: '' });
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
      const data = await api.reserveSeat({
        passengerId: Number(form.passengerId),
        routeId: Number(form.routeId),
        seatNumber: Number(form.seatNumber),
      });
      setResult({
        type: 'success',
        text: `${data.message} (Reservation ID: ${data.reservationId}, Fare: ₹${Number(data.fare).toFixed(2)})`,
      });
    } catch (err) {
      setResult({ type: 'error', text: err.message });
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <label>
        Passenger ID
        <input type="number" name="passengerId" min="1" value={form.passengerId} onChange={handleChange} required />
      </label>
      <label>
        Route ID
        <input type="number" name="routeId" min="1" value={form.routeId} onChange={handleChange} required />
      </label>
      <label>
        Seat Number
        <input type="number" name="seatNumber" min="1" value={form.seatNumber} onChange={handleChange} required />
      </label>
      <button type="submit" disabled={busy}>{busy ? 'Reserving…' : 'Reserve Seat'}</button>
      {result && <p className={`message ${result.type}`}>{result.text}</p>}
    </form>
  );
}
