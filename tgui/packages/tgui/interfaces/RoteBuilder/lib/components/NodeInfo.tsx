// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/CircuitInfo.jsx
import { Box, Button, Stack } from 'tgui-core/components';

export type NodeInfoNotice = {
  content: string;
  color?: string;
  icon?: string;
};

type Props = {
  name?: string;
  desc?: string;
  notices: NodeInfoNotice[];
  [key: string]: unknown;
};

export const NodeInfo = (props: Props) => {
  const { name, desc, notices, ...rest } = props;
  return (
    <Box {...rest}>
      <Stack fill vertical justify="space-around">
        {!!desc && <Stack.Item maxWidth="200px">{desc}</Stack.Item>}
        <Stack.Item>
          <Stack vertical>
            {notices.map((val, index) => (
              <Stack.Item key={index}>
                <Button
                  content={val.content}
                  color={val.color}
                  icon={val.icon}
                  fluid
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
