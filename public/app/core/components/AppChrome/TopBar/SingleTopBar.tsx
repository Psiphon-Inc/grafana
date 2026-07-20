import { css } from '@emotion/css';
import React, { memo } from 'react';

import { GrafanaTheme2, NavModelItem } from '@grafana/data';
import { Components } from '@grafana/e2e-selectors';
import { t } from '@grafana/i18n';
import { ScopesContextValue } from '@grafana/runtime';
import { Icon, Stack, ToolbarButton, useStyles2 } from '@grafana/ui';
import { config } from 'app/core/config';
import { MEGA_MENU_TOGGLE_ID } from 'app/core/constants';
import { useGrafana } from 'app/core/context/GrafanaContext';
import { contextSrv } from 'app/core/core';
import { useMediaQueryMinWidth } from 'app/core/hooks/useMediaQueryMinWidth';
import { HOME_NAV_ID } from 'app/core/reducers/navModel';
// Psiphon change - import AccessControlAction needed for permissions information
import { AccessControlAction } from 'app/types/accessControl';
import { useSelector } from 'app/types/store';

import { Branding } from '../../Branding/Branding';
import { Breadcrumbs } from '../../Breadcrumbs/Breadcrumbs';
import { buildBreadcrumbs } from '../../Breadcrumbs/utils';
import { ExtensionToolbarItem } from '../ExtensionSidebar/ExtensionToolbarItem';
import { HistoryContainer } from '../History/HistoryContainer';
import { NavToolbarSeparator } from '../NavToolbar/NavToolbarSeparator';
import { QuickAdd } from '../QuickAdd/QuickAdd';

import { HelpTopBarButton } from './HelpTopBarButton';
import { InviteUserButton } from './InviteUserButton';
import { ProfileButton } from './ProfileButton';
import { SignInLink } from './SignInLink';
import { SingleTopBarActions } from './SingleTopBarActions';
import { TopSearchBarCommandPaletteTrigger } from './TopSearchBarCommandPaletteTrigger';
import { getChromeHeaderLevelHeight } from './useChromeHeaderHeight';

interface Props {
  sectionNav: NavModelItem;
  pageNav?: NavModelItem;
  onToggleMegaMenu(): void;
  onToggleKioskMode(): void;
  actions?: React.ReactNode;
  breadcrumbActions?: React.ReactNode;
  scopes?: ScopesContextValue | undefined;
  showToolbarLevel: boolean;
}

export const SingleTopBar = memo(function SingleTopBar({
  onToggleMegaMenu,
  onToggleKioskMode,
  pageNav,
  sectionNav,
  scopes,
  actions,
  breadcrumbActions,
  showToolbarLevel,
}: Props) {
  const { chrome } = useGrafana();
  const state = chrome.useState();
  const menuDockedAndOpen = !state.chromeless && state.megaMenuDocked && state.megaMenuOpen;
  const styles = useStyles2(getStyles, menuDockedAndOpen);
  const profileNode = useSelector((state) => state.navIndex['profile']);
  const homeNav = useSelector((state) => state.navIndex)[HOME_NAV_ID];
  const breadcrumbs = buildBreadcrumbs(sectionNav, pageNav, homeNav);
  const unifiedHistoryEnabled = config.featureToggles.unifiedHistory;
  const isSmallScreen = !useMediaQueryMinWidth('sm');
  // Psiphon change - check if user can create Dashboards. If yes, the user is an Admin or
  // Editor. Menu toggle and search should only be available to Admin or Editor users.
  const hasMenu = contextSrv.hasPermission(AccessControlAction.DashboardsCreate);

  return (
    <>
      <div className={styles.layout}>
        <Stack minWidth={0} gap={0.5} alignItems="center" flex={{ xs: 2, lg: 1 }}>
          {/* Psiphon change - show the menu toggle only for admin or editor users; other
              users see the plain logo without a menu */}
          {!menuDockedAndOpen && hasMenu && (
            <ToolbarButton
              narrow
              id={MEGA_MENU_TOGGLE_ID}
              onClick={onToggleMegaMenu}
              tooltip={t('navigation.megamenu.open', 'Open menu')}
            >
              <Stack gap={0} alignItems="center">
                {/* Psiphon change - apply custom logo sizing class to menu logo */}
                <Branding.MenuLogo className={styles.imgLogo} />
                <Icon size="sm" name="angle-down" />
              </Stack>
            </ToolbarButton>
          )}
          {!menuDockedAndOpen && !hasMenu && <Branding.MenuLogo className={styles.imgLogo} />}
          <Breadcrumbs breadcrumbs={breadcrumbs} className={styles.breadcrumbsWrapper} />
          {!showToolbarLevel && breadcrumbActions}
        </Stack>

        <Stack
          gap={0.5}
          alignItems="center"
          justifyContent={'flex-end'}
          flex={1}
          data-testid={!showToolbarLevel ? Components.NavToolbar.container : undefined}
          minWidth={{ xs: 'unset', lg: 0 }}
        >
          {/* Psiphon change - hide search bar for non admin/editor users */}
          {hasMenu && <TopSearchBarCommandPaletteTrigger />}
          {unifiedHistoryEnabled && !isSmallScreen && <HistoryContainer />}
          {!isSmallScreen && <QuickAdd />}
          <HelpTopBarButton isSmallScreen={isSmallScreen} />
          <NavToolbarSeparator />
          {!isSmallScreen && <ExtensionToolbarItem compact={isSmallScreen} />}
          {!showToolbarLevel && actions}
          {!contextSrv.user.isSignedIn && <SignInLink />}
          <InviteUserButton />
          {profileNode && <ProfileButton profileNode={profileNode} onToggleKioskMode={onToggleKioskMode} />}
        </Stack>
      </div>
      {showToolbarLevel && (
        <SingleTopBarActions scopes={scopes} actions={actions} breadcrumbActions={breadcrumbActions} />
      )}
    </>
  );
});

const getStyles = (theme: GrafanaTheme2, menuDockedAndOpen: boolean) => ({
  layout: css({
    height: getChromeHeaderLevelHeight(),
    display: 'flex',
    gap: theme.spacing(2),
    alignItems: 'center',
    padding: theme.spacing(0, 1),
    paddingLeft: menuDockedAndOpen ? theme.spacing(3.5) : theme.spacing(0.75),
    borderBottom: `1px solid ${theme.colors.border.weak}`,
    justifyContent: 'space-between',
  }),
  breadcrumbsWrapper: css({
    display: 'flex',
    overflow: 'hidden',
    [theme.breakpoints.down('sm')]: {
      minWidth: '40%',
    },
  }),
  img: css({
    alignSelf: 'center',
    height: theme.spacing(3),
    width: theme.spacing(3),
  }),
  // Psiphon change - add logo sizing class to fit aspect ratio of PDE logo (726x45)
  imgLogo: css({
    alignSelf: 'center',
    height: theme.spacing(2),
    width: theme.spacing(32.27),
    maxWidth: '40vw',
    objectFit: 'contain',
  }),
  kioskToggle: css({
    [theme.breakpoints.down('lg')]: {
      display: 'none',
    },
  }),
});
