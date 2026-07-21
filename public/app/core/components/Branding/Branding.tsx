import { css, cx } from '@emotion/css';
import { FC } from 'react';

import { colorManipulator } from '@grafana/data';
import { useTheme2 } from '@grafana/ui';
// Psiphon change - import Psiphon logos and login background instead of Grafana ones
import grafanaPsiphonLoginPng from 'img/grafana-psiphon-login.png';
import psiphonLogoPng from 'img/psiphon-logo-512x512.png';
import psiphonPdeIconPng from 'img/psiphon_pde_icon.png';

export interface BrandComponentProps {
  className?: string;
  children?: JSX.Element | JSX.Element[];
}

// Psiphon change - use Psiphon logo on login page instead of Grafana logo
export const LoginLogo: FC<BrandComponentProps & { logo?: string }> = ({ className, logo }) => {
  return <img className={className} src={psiphonLogoPng} alt="Psiphon logo" />;
};

const LoginBackground: FC<BrandComponentProps> = ({ className, children }) => {
  const theme = useTheme2();

  // Psiphon change - use custom background image on login page
  const background = css({
    '&:before': {
      content: '""',
      position: 'fixed',
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      background: `url(${grafanaPsiphonLoginPng})`,
      backgroundPosition: 'top center',
      backgroundSize: 'auto',
      backgroundRepeat: 'no-repeat',

      opacity: 0,

      [theme.transitions.handleMotion('no-preference', 'reduce')]: {
        transition: 'opacity 3s ease-in-out',
      },

      [theme.breakpoints.up('md')]: {
        backgroundPosition: 'center',
        backgroundSize: 'cover',
      },
    },
  });

  return <div className={cx(background, className)}>{children}</div>;
};

// Psiphon change - use psiphon logo on menu bar instead of Grafana logo
const MenuLogo: FC<BrandComponentProps> = ({ className }) => {
  return <img className={className} src={psiphonPdeIconPng} alt="Psiphon Data Engine" />;
};

// Psiphon change - square icon variant for narrow slots (mega menu header), where the
// wide PDE wordmark does not fit next to the org switcher and dock button
const MenuLogoIcon: FC<BrandComponentProps> = ({ className }) => {
  return <img className={className} src={psiphonLogoPng} alt="Psiphon Data Engine" />;
};

const LoginBoxBackground = () => {
  const theme = useTheme2();
  return css({
    background: colorManipulator.alpha(theme.colors.background.primary, 0.7),
    backgroundSize: 'cover',
  });
};

// Psiphon change - remove Grafana welcome message on login page and change app title
export class Branding {
  static LoginLogo = LoginLogo;
  static LoginBackground = LoginBackground;
  static MenuLogo = MenuLogo;
  // Psiphon change - square icon variant for narrow slots
  static MenuLogoIcon = MenuLogoIcon;
  static LoginBoxBackground = LoginBoxBackground;
  static AppTitle = 'Psiphon Data Engine';
  // Psiphon note - LoginTitle is never rendered (our LoginLayout removes the welcome
  // message) but the field must exist because PasswordlessConfirmationForm assigns to it.
  static LoginTitle = 'Welcome to Psiphon Data Engine';
  static HideEdition = false;
  static GetLoginSubTitle = (): null | string => {
    return null;
  };
}
