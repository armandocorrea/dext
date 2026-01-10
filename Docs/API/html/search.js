
document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('unitSearch');
    const unitItems = document.querySelectorAll('.unit-item');

    searchInput.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase();
        unitItems.forEach(item => {
            const text = item.textContent.toLowerCase();
            if (text.includes(term)) {
                item.style.display = 'block';
            } else {
                item.style.display = 'none';
            }
        });
    });
});
