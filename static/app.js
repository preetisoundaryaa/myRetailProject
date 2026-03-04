const shelfEl = document.getElementById('shelf');
const messageEl = document.getElementById('message');

async function fetchItems() {
  const res = await fetch('/api/items');
  const data = await res.json();
  return data.items || [];
}

function setMessage(text, isError = false) {
  messageEl.textContent = text;
  messageEl.style.color = isError ? '#b23' : '#1d6d2e';
}

async function buyItem(itemId) {
  const res = await fetch('/api/purchase', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ item_id: itemId, qty: 1 })
  });
  const data = await res.json();

  if (!res.ok || !data.ok) {
    setMessage(data.error || 'Could not complete purchase', true);
    return;
  }

  setMessage(`Purchased ${data.item.name} for $${data.total}`);
  await renderShelf();
}

function itemCard(item) {
  const card = document.createElement('section');
  card.className = 'item-card';

  // Keeping this plain JS so it's easy to debug during interviews.
  card.innerHTML = `
    <h3>${item.name}</h3>
    <p>ID: ${item.id}</p>
    <p>Price: $${item.price.toFixed(2)}</p>
    <p>In stock: ${item.qty}</p>
    <button ${item.qty === 0 ? 'disabled' : ''}>Buy</button>
  `;

  const button = card.querySelector('button');
  button.addEventListener('click', () => buyItem(item.id));
  return card;
}

async function renderShelf() {
  try {
    const items = await fetchItems();
    shelfEl.innerHTML = '';
    items.forEach((item) => shelfEl.appendChild(itemCard(item)));
  } catch (err) {
    setMessage('Failed to load shelf data', true);
    console.error(err);
  }
}

renderShelf();
