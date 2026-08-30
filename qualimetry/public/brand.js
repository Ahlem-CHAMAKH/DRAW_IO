// Swaps the fallback "G" monogram for a real logo file, if one has been
// dropped in at public/gosi-logo.png. Keeps working with no logo present.
(function () {
  const mark = document.getElementById("brandMark");
  if (!mark) return;
  const img = new Image();
  img.alt = "GOSI";
  img.onload = () => {
    mark.textContent = "";
    mark.style.background = "transparent";
    mark.appendChild(img);
  };
  img.src = "/gosi-logo.png";
})();
