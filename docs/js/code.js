hljs.highlightAll();
window.onload = () => {
  document.querySelectorAll('pre code').forEach(block => {
    const rootElement = block.parentElement;
    const lineCodes = block.innerHTML.split(/\n/);
    if (lineCodes[lineCodes.length - 1] === '') lineCodes.pop();
    const lineLength = lineCodes.length;

    let codeLineHtml = '';
    for (let i = 0; i < lineLength; i++) {
      codeLineHtml += `<div class="line">${i + 1}</div>`;
    }

    let codeHtml = '';
    for (let i = 0; i < lineLength; i++) {
      codeHtml += `<div class="line">${lineCodes[i]}</div>`;
    }

    block.className += ' highlight';
    const figure = document.createElement('figure');
    figure.className = block.className;
    figure.innerHTML = `<table><tbody><tr><td class="gutter"><pre>${codeLineHtml}</pre></td><td class="code"><pre>${codeHtml}</pre></td></tr></tbody></table>`;

    rootElement.parentElement.replaceChild(figure, rootElement);
  });
};
