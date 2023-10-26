import { css, cx } from '@emotion/css';
import React, { FC } from 'react';

import { colorManipulator } from '@grafana/data';
import { useTheme2, styleMixins } from '@grafana/ui';

export interface BrandComponentProps {
  className?: string;
  children?: JSX.Element | JSX.Element[];
}

// Psiphon change - use Psiphon logo on login page instead of Grafana logo
export const LoginLogo: FC<BrandComponentProps & { logo?: string }> = ({ className, logo }) => {
  return <img className={className} src="public/img/psiphon-logo-512x512.png" alt="Psiphon logo" />;
};

const LoginBackground: FC<BrandComponentProps> = ({ className, children }) => {
  const theme = useTheme2();

  // Psiphon change - use custom background image on login page
  const background = css`
    &:before {
      content: '';
      position: fixed;
      left: 0;
      right: 0;
      bottom: 0;
      top: 0;
      background: url('public/img/grafana-psiphon-login.png');
      background-position: top center;
      background-size: auto;
      background-repeat: no-repeat;

      opacity: 0;
      transition: opacity 3s ease-in-out;

      @media ${styleMixins.mediaUp(theme.v1.breakpoints.md)} {
        background-position: center;
        background-size: cover;
      }
    }
  `;

  return <div className={cx(background, className)}>{children}</div>;
};

// Psiphon change - use psiphon logo on menu bar instead of Grafana logo
const MenuLogo: FC<BrandComponentProps> = ({ className }) => {
  return <img className={className} src="public/img/psiphon_pde_icon.png" alt="Psiphon Data Engine" />;
};

const LoginBoxBackground = () => {
  const theme = useTheme2();
  return css`
    background: ${colorManipulator.alpha(theme.colors.background.primary, 0.7)};
    background-size: cover;
  `;
};

// Psiphon change - remove Grafana welcome message on login page and change app title
export class Branding {
  static LoginLogo = LoginLogo;
  static LoginBackground = LoginBackground;
  static MenuLogo = MenuLogo;
  static LoginBoxBackground = LoginBoxBackground;
  static AppTitle = 'Psiphon Data Engine';
  static HideEdition = false;
  static GetLoginSubTitle = (): null | string => {
    return null;
  };
}
