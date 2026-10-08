import { useState } from 'react';
import { api } from '../api';

export default function FareCalculator() {
  const [routeId, setRouteId] = useState('');
  const [result, setResult] = useState(null);
  const [busy, setBusy] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setBusy(true);
    setResult(null);
    try {
      const data = await api.getFare(routeId);
      setResult({ type: 'success', text: `Fare: ₹${Number(data.fare).toFixed(2)}` });
    } catch (err) {
      setResult({ type: 'error', text: err.message });
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <label>
        Route ID
        <input type="number" min="1" value={routeId} onChange={(e) => setRouteId(e.target.value)} required />
      </label>
      <button type="submit" disabled={busy}>{busy ? 'Calculating…' : 'Calculate Fare'}</button>
      {result && <p className={`message ${result.type}`}>{result.text}</p>}
    </form>
  );
}
