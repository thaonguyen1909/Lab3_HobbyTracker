export function placePopover(anchor, content, viewport, gap=6, margin=8){
 const width=Math.min(content.width,Math.max(0,viewport.width-margin*2));
 const below=Math.max(0,viewport.height-margin-anchor.bottom-gap);
 const above=Math.max(0,anchor.top-margin-gap);
 const side=content.height<=below||below>=above?'bottom':'top';
 const maxHeight=Math.min(side==='bottom'?below:above,Math.max(0,viewport.height-margin*2));
 const height=Math.min(content.height,maxHeight);
 const left=Math.max(margin,Math.min(anchor.right-width,viewport.width-margin-width));
 const top=Math.max(margin,Math.min(side==='bottom'?anchor.bottom+gap:anchor.top-gap-height,viewport.height-margin-height));
 return {left,top,width,maxHeight,side};
}
