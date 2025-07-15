<?php

/**
 * @copyright 2023 Biapy
 * @license MIT
 */

declare(strict_types=1);

use App\Kernel;
use Symfony\Bundle\FrameworkBundle\Console\Application;

require dirname(__DIR__).'/../tests/bootstrap.php';

/** @psalm-suppress RedundantCondition,TypeDoesNotContainType */
$env = (isset($_SERVER['APP_ENV']) && is_string($_SERVER['APP_ENV'])) ? $_SERVER['APP_ENV'] : 'dev';
$debug = (bool) ($_SERVER['APP_DEBUG'] ?? false);

$kernel = new Kernel($env, $debug);

return new Application($kernel);
