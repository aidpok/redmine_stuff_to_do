document.addEventListener('DOMContentLoaded', function() {
  var dragged = null;
  var orderFields = document.querySelector('.stuff-to-do-order-fields');
  var saveButton = document.getElementById('stuff-to-do-save-order');
  var saveState = document.getElementById('stuff-to-do-save-state');
  var originalOrder = currentOrder().join('|');

  function currentOrder() {
    return Array.from(document.querySelectorAll('.sortable-stuff-to-do .stuff-to-do-item[data-queue-value]')).map(function(item) {
      return item.dataset.queueValue;
    });
  }

  function updateOrderFields() {
    if (!orderFields) return;
    orderFields.innerHTML = '';
    document.querySelectorAll('.sortable-stuff-to-do .stuff-to-do-item[data-queue-value]').forEach(function(item) {
      var input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'queue_items[]';
      input.value = item.dataset.queueValue;
      orderFields.appendChild(input);
    });
    updatePositions();
    updateSaveState();
  }

  function updatePositions() {
    document.querySelectorAll('.sortable-stuff-to-do').forEach(function(list) {
      list.querySelectorAll('.stuff-to-do-position').forEach(function(position, index) {
        position.textContent = index + 1;
      });
    });
  }

  function updateSaveState() {
    var changed = currentOrder().join('|') !== originalOrder;
    if (saveButton) saveButton.disabled = !changed;
    if (saveState) saveState.textContent = changed ? 'Unsaved changes' : 'No changes';
  }

  window.addEventListener('beforeunload', function(event) {
    if (currentOrder().join('|') === originalOrder) return;

    event.preventDefault();
    event.returnValue = '';
  });

  document.querySelectorAll('.stuff-to-do-reorder-form').forEach(function(form) {
    form.addEventListener('submit', function() {
      originalOrder = currentOrder().join('|');
      updateSaveState();
    });
  });

  document.querySelectorAll('.sortable-stuff-to-do, .available-list').forEach(function(list) {
    list.addEventListener('dragstart', function(event) {
      dragged = event.target.closest('.stuff-to-do-item');
      if (dragged) dragged.classList.add('dragging');
    });
    list.addEventListener('dragend', function() {
      if (dragged) dragged.classList.remove('dragging');
      updateOrderFields();
      dragged = null;
    });
    list.addEventListener('dragover', function(event) {
      if (!list.classList.contains('sortable-stuff-to-do')) return;
      event.preventDefault();
      if (!dragged) return;
      var after = Array.from(list.querySelectorAll('.stuff-to-do-item:not(.dragging)')).find(function(item) {
        return event.clientY <= item.getBoundingClientRect().top + item.offsetHeight / 2;
      });
      if (after) list.insertBefore(dragged, after); else list.appendChild(dragged);
      updateOrderFields();
    });
  });

  updateOrderFields();
});
