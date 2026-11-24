// Load the platform map SDK before Flutter initializes its map plugin.
(() => {
  const startFlutter = () => {
    const script = document.createElement('script');
    script.src = 'flutter_bootstrap.js';
    script.async = true;
    document.body.appendChild(script);
  };
  const key = window.foodmarksMapsApiKey;
  if (!key) {
    startFlutter();
    return;
  }
  const maps = document.createElement('script');
  maps.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}`;
  maps.async = true;
  maps.onload = startFlutter;
  maps.onerror = () => {
    console.error('Google Maps could not load. Check the local map configuration and network.');
    startFlutter();
  };
  document.body.appendChild(maps);
})();
