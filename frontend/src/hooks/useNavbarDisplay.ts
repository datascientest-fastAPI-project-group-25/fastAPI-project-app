import { useEffect, useState } from 'react';

export function useNavbarDisplay() {
  const [display, setDisplay] = useState('none');

  useEffect(() => {
    function handleResize() {
      setDisplay(window.innerWidth >= 768 ? 'flex' : 'none');
    }

    handleResize(); // Initial check
    window.addEventListener('resize', handleResize);

    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return display;
}
