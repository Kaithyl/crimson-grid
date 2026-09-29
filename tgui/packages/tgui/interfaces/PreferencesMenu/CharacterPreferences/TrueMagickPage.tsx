// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { useBackend } from 'tgui/backend';
import { AnimatedNumber, Button, Section, Stack, Tooltip, } from 'tgui-core/components';

import type { PreferencesMenuData } from '../types';

const KEY_SPHERE_POINTS = '/datum/st_stat/sphere';
const KEY_FREEBIE_POINTS = '/datum/st_stat/freebie'

type MageStat = {
  name: string;
  desc: string;
  score: number;
  bonus_score: number;
  max_score: number;
  editable: number;
  category: string;
  subcategory: string;
  points: number;
  abstract_type: string;
};

export function TrueMagickPage() {
  const { act, data } = useBackend<PreferencesMenuData>();
  if (!data) return;

  const stats: Record<string, MageStat> = (
    data as PreferencesMenuData & { mage_stats: Record<string, MageStat> }
  ).mage_stats ?? {};

  if (!stats || Object.keys(stats).length === 0) return null;

  // Hardcoding this in for now
  const pointStats = [
    {
      path: 'sphere',
      name: 'Sphere Points',
      points: stats[KEY_SPHERE_POINTS]?.points ?? 0,
    },
    // Fetch freebie points already sent to Stats.tsx
    {
      path: 'freebie',
      name: 'Freebie Points',
      points: data.stats[KEY_FREEBIE_POINTS]?.points ?? 0,
    },
  ];

  const grouped: Record<string, Record<string, string[]>> = {};
  Object.entries(stats).forEach(([path, statData]) => {
    if (path === statData.abstract_type) return;
    const category = statData.category;
    const subcategory = statData.subcategory ?? 'General';
    if (!grouped[category]) grouped[category] = {};
    if (!grouped[category][subcategory]) grouped[category][subcategory] = [];
    grouped[category][subcategory].push(path);
  });

  return (
    <Stack vertical fill className="PreferencesMenu__Stats">
      {/* Header row */}
      <Stack.Item className="PreferencesMenu__Stats__header">
        <Stack>
          <Stack.Item>
            <Button
              className="reset-button"
              icon="trash"
              onClick={() => act('reset_mage_stats')}
              color="red"
              tooltip="Reset Stats"
              tooltipPosition="top"
            />
          </Stack.Item>
          <Stack.Item>
            {pointStats.map((pointStat) => (
              <Section inline my="10px" mx="5px" key={pointStat.path}>
                <Stack.Item inline my="10px" mx="5px" key={pointStat.path}>
                  <b>{pointStat.name}: </b>
                  <AnimatedNumber value={pointStat.points} />
                </Stack.Item>
              </Section>
            ))}
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Categories - Display advantages first */}
      {Object.entries(grouped)
        .sort(([a], [b]) => {
          const order = ['advantage', 'sphere'];
          const ia = order.indexOf(a.toLowerCase());
          const ib = order.indexOf(b.toLowerCase());
          if (ia !== -1 && ib !== -1) return ia - ib;
          if (ia !== -1) return -1;
          if (ib !== -1) return 1;
          return 0;
        })
        .map(([category, subcats]) => (
        <Stack.Item key={category} className="PreferencesMenu__Stats__category">
          <b>{category}</b>
          <Stack>
            {/* Subcategories */}
            {Object.entries(subcats).map(([subcat, paths]) => (
              <Stack.Item
                key={subcat}
                className="PreferencesMenu__Stats__category__subcategory"
              >
                <i>{subcat}</i>
                <Stack vertical>
                  {paths.map((statPath) => {
                    const statData = stats[statPath];
                    const score = statData.score;
                    const bonus_score = statData.bonus_score;
                    const max = statData.max_score;
                    const label = statData.name;
                    const editable = statData.editable;
                    const filled = '●'.repeat(score);
                    const filled_bonus = '●'.repeat(bonus_score);
                    const empty = '○'.repeat(max - score);

                    return (
                      <Stack.Item key={statPath} className="stat">
                        <Stack fill>
                          <Stack.Item grow basis="50%" className="stat-label">
                            <Tooltip content={statData.desc}>{label}</Tooltip>
                          </Stack.Item>
                          <Stack.Item grow basis="50%" textAlign="right">
                            <Stack fill g={1}>
                              {editable === 1 && (
                                <>
                                  <Stack.Item>
                                    <Button
                                      icon="minus"
                                      disabled={score <= 0}
                                      onClick={() =>
                                        act('decrease_mage_stat', {
                                          stat: statPath,
                                        })
                                      }
                                    />
                                  </Stack.Item>
                                  <Stack.Item>
                                    <Button
                                      icon="plus"
                                      disabled={score >= max}
                                      onClick={() =>
                                        act('increase_mage_stat', {
                                          stat: statPath,
                                        })
                                      }
                                    />
                                  </Stack.Item>
                                </>
                              )}
                              <Stack.Item className="stat-dots">
                                <span className="filled">{filled}</span>
                                <span className="empty">{empty}</span>
                                <span className="filled_bonus">
                                  {filled_bonus}
                                </span>
                              </Stack.Item>
                            </Stack>
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                    );
                  })}
                </Stack>
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
      ))}
    </Stack>
  );
}
