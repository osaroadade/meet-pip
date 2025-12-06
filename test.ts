const checkBlx = () => {
	const elems = [...document.querySelectorAll('.qg7mD.r6DyN.xm86Be.JBY0Kc.eXUaib.KXY1yb')];
	const active = elems.some(el => el.classList.contains('BlxGDf'))
	console.clear()
	console.log('%c BlxGDf is currently ACTIVE → ' + (active ? '%cYES' : '%cNO'),
		'font-size:20px; color:white;',
		active ? 'color:lime; font-size:40px' : 'color:gray; font-size:40px');
	console.log('Found', elems.length, 'candidate elements');
	return active;
}